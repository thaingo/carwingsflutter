import 'package:blowfish_native/blowfish_native.dart';
import 'package:carwingsflutter/help_page.dart';
import 'package:carwingsflutter/main_page.dart';
import 'package:carwingsflutter/preferences_manager.dart';
import 'package:carwingsflutter/util.dart';
import 'package:dartcarwings/dartcarwings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  LoginPage(this.session, [this.autoLogin = true]);

  CarwingsSession session;
  bool autoLogin;

  @override
  _LoginPageState createState() => new _LoginPageState(session, autoLogin);
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PreferencesManager preferencesManager = new PreferencesManager();

  CarwingsSession _session;

  bool _autoLogin;

  TextEditingController _usernameTextController = new TextEditingController();
  TextEditingController _passwordTextController = new TextEditingController();

  CarwingsRegion _regionSelected = CarwingsRegion.Europe;

  bool _rememberLoginSettings = false;

  String _serverStatus;

  _LoginPageState(this._session, [this._autoLogin = false]);

  @override
  void initState() {
    super.initState();
    preferencesManager.getLoginSettings().then((login) {
      if (login != null) {
        _usernameTextController.text = login.username;
        _passwordTextController.text = login.password;
        _regionSelected = login.region;
        setState(() {
          _rememberLoginSettings = true;
        });
        if (_autoLogin) _doLogin();
      }
    });
    preferencesManager.getGeneralSettings().then((generalSettings) {
      if (generalSettings.timeZoneOverride) {
        _session.setTimeZoneOverride(generalSettings.timeZone);
      }
    });
    _getServerStatus();
  }

  _getServerStatus() async {
    http.Response response =
        await http.get("https://wkjeldsen.dk/myleaf/server_status");
    setState(() {
      _serverStatus = response.body.trim();
    });
  }

  _doLogin() {
    Util.showLoadingDialog(context, 'Signing in...');

    _getServerStatus();

    _session
        .login(
            username: _usernameTextController.text.trim(),
            password: _passwordTextController.text.trim(),
            blowfishEncryptCallback: (String key, String password) async {
              var encodedPassword = await BlowfishNative.encrypt(key, password);
              return encodedPassword;
            },
            region: _regionSelected)
        .then((vehicle) {
      Util.dismissLoadingDialog(context);

      // Login was successful, push main view
      _openMainPage();

      if (_rememberLoginSettings) {
        preferencesManager.setLoginSettings(
            _session.username, _session.password, _regionSelected);
      } else {
        preferencesManager.clearLoginSettings();
      }
    }).catchError((error) {
      Util.dismissLoadingDialog(context);

      scaffoldKey.currentState.showSnackBar(new SnackBar(
          duration: new Duration(seconds: 5),
          content: new Text('Login failed. Please try again')));

      if (_serverStatus != null && _serverStatus.isNotEmpty) {
        scaffoldKey.currentState.showSnackBar(new SnackBar(
            duration: new Duration(seconds: 10),
            content: new Text(_serverStatus)));
      }
    });
  }

  List<DropdownMenuItem<CarwingsRegion>> _buildRegionAndGetDropDownMenuItems() {
    List<DropdownMenuItem<CarwingsRegion>> items = new List();
    for (CarwingsRegion region in CarwingsRegion.values) {
      items.add(new DropdownMenuItem(
          value: region,
          child:
              new Text(region.toString().replaceAll('CarwingsRegion\.', ''))));
    }
    return items;
  }

  _openMainPage() {
    Navigator.of(context).pushReplacement(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new MainPage(_session);
      },
    ));
  }

  _openHelpPage() {
    Navigator.of(context).push(new MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return new HelpPage();
      },
    ));
  }

  _openPreferencesPage() {
    Navigator.pushNamed(context, '/preferences');
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        key: scaffoldKey,
        body: Theme(
            data: Theme.of(context).copyWith(
                primaryColorDark: Colors.white,
                primaryColorLight: Colors.white,
                textTheme: TextTheme(body1: TextStyle(color: Colors.white)),
                primaryColor: Colors.white,
                accentColor: Colors.white,
                buttonColor: Util.isDarkTheme(context)
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                hintColor: Colors.white,
                canvasColor: Theme.of(context).primaryColor,
                toggleableActiveColor: Colors.white),
            child: new Container(
              padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 0.0),
              child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      child: ImageIcon(
                        AssetImage('images/car-leaf.png'),
                        color: Colors.white,
                        size: 100.0,
                      ),
                      onLongPress: _openPreferencesPage,
                    ),
                    new Padding(padding: const EdgeInsets.all(10.0)),
                    new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'Enter your You+Nissan, also known as NissanConnect, credentials below',
                          style: TextStyle(fontSize: 18.0, color: Colors.white),
                        ),
                        TextFormField(
                          controller: _usernameTextController,
                          autofocus: false,
                          decoration: InputDecoration(labelText: 'Username'),
                        ),
                        TextFormField(
                          controller: _passwordTextController,
                          decoration: InputDecoration(labelText: 'Password'),
                          obscureText: true,
                        ),
                        new Row(
                          children: <Widget>[
                            Text(
                              'Region',
                              style: TextStyle(color: Colors.white),
                            ),
                            new Padding(padding: const EdgeInsets.all(10.0)),
                            new DropdownButton(
                              value: _regionSelected,
                              items: _buildRegionAndGetDropDownMenuItems(),
                              onChanged: (region) {
                                setState(() {
                                  _regionSelected = region;
                                });
                              },
                            ),
                            FlatButton.icon(
                                onPressed: _openHelpPage,
                                icon: Icon(
                                  Icons.help,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Help',
                                  style: TextStyle(color: Colors.white),
                                ))
                          ],
                        ),
                        new Padding(padding: const EdgeInsets.all(10.0)),
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              'Remember credentials',
                              style: TextStyle(color: Colors.white),
                            ),
                            Switch(
                                value: _rememberLoginSettings,
                                onChanged: (bool value) {
                                  setState(() {
                                    _rememberLoginSettings = value;
                                  });
                                }),
                            RaisedButton(
                                child: new Text("Sign in"), onPressed: _doLogin)
                          ],
                        )
                      ],
                    )
                  ]),
            )));
  }
}
