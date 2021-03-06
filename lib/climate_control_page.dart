import 'package:carwingsflutter/util.dart';
import 'package:dartcarwings/dartcarwings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _ClimateControlPageState extends State<ClimateControlPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  CarwingsSession _session;

  bool _climateControlIsReady = false;
  bool _climateControlOn = false;
  CarwingsCabinTemperature _cabinTemperature;

  DateTime _startDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _currentDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _climateControlScheduled;

  _ClimateControlPageState(this._session);

  @override
  void initState() {
    super.initState();
    _session.vehicle.requestHVACStatus().then((hvac) {
      setState(() {
        _climateControlOn = hvac.isRunning;
        _climateControlIsReady = true;
      });
      _session.vehicle.requestClimateControlScheduleGet().then((date) {
        setState(() {
          _climateControlScheduled = date;
        });
        if(!_session.isFirstGeneration) {
          _session.vehicle.requestCabinTemperature().then((cabinTemperature) {
            setState(() {
              _cabinTemperature = cabinTemperature;
            });
          });
        }
      });
    });
  }

  _climateControlToggle() {
    setState(() {
      Util.showLoadingDialog(context);
      _climateControlOn = !_climateControlOn;
      if (_climateControlOn) {
        _session.vehicle
            .requestClimateControlSchedule(DateTime.now())
            .then((_) {
          _snackbar('Climate Control was turned on');
        }).catchError((error) {
          _climateControlOn = !_climateControlOn;
          _snackbar('Climate Control failed to turn on');
        }).whenComplete(() => Util.dismissLoadingDialog(context));
      } else {
        _session.vehicle.requestClimateControlOff().then((_) {
          _snackbar('Climate Control was turned off');
        }).catchError((error) {
          _climateControlOn = !_climateControlOn;
          _snackbar('Climate Control failed to turn off');
        }).whenComplete(() => Util.dismissLoadingDialog(context));
      }
    });
  }

  _climateControlScheduledCancel() {
    Util.showLoadingDialog(context);
    _session.vehicle.requestClimateControlScheduleCancel().then((_) {
      _snackbar('Scheduled Climate Control was canceled');
      setState(() {
        _climateControlScheduled = null;
      });
    }).catchError((error) {
      _snackbar('Could not cancel scheduled Climate Control');
    }).whenComplete(() => Util.dismissLoadingDialog(context));
  }

  _climateControlSchedule() {
    if (_climateControlScheduled != null) {
      _climateControlScheduledCancel();
    } else {
      showDatePicker(
              context: context,
              initialDate: _currentDate,
              firstDate: _startDate,
              lastDate: DateTime.now().add(Duration(days: 30)))
          .then((date) {
        if (date != null) {
          showTimePicker(context: context, initialTime: TimeOfDay.now())
              .then((time) {
            if (time != null) {
              _currentDate = DateTime(
                  date.year, date.month, date.day, time.hour, time.minute);
              Util.showLoadingDialog(context);
              _session.vehicle
                  .requestClimateControlSchedule(_currentDate)
                  .then((_) {
                setState(() {
                  _climateControlScheduled = _currentDate;
                });
                _snackbar('Climate Control was scheduled');
              }).catchError((error) {
                _snackbar('Climate Control schedule failed');
              }).whenComplete(() => Util.dismissLoadingDialog(context));
            }
          });
        }
      });
    }
  }

  _snackbar(message) {
    scaffoldKey.currentState.showSnackBar(
        SnackBar(duration: Duration(seconds: 5), content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: Text("Climate Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: ImageIcon(AssetImage('images/aircondition.png')),
              iconSize: 200.0,
              color: _climateControlOn
                  ? Util.primaryColor(context)
                  : Theme.of(context).disabledColor,
              onPressed: _climateControlToggle,
            ),
            Text(
              'Climate Control is ${_climateControlIsReady ? _climateControlOn ? 'on' : 'off' : 'updating...'}',
              style: TextStyle(fontSize: 18.0),
            ),
            !_session.isFirstGeneration
                ? Text(
                    'Cabin temperature is ${_cabinTemperature != null ? '${_cabinTemperature.temperature}°' : 'updating...'}')
                : Column(),
            IconButton(
              icon: Icon(Icons.access_time),
              iconSize: 200.0,
              color: _climateControlScheduled != null
                  ? Util.primaryColor(context)
                  : Theme.of(context).disabledColor,
              onPressed: _climateControlSchedule,
            ),
            Text(
              _climateControlScheduled != null
                  ? 'At ${DateFormat('HH:mm \'this\' EEEE').format(_climateControlScheduled)}'
                  : 'Not scheduled',
              style: TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      ),
    );
  }
}

class ClimateControlPage extends StatefulWidget {
  ClimateControlPage(this.session);

  CarwingsSession session;

  @override
  _ClimateControlPageState createState() => _ClimateControlPageState(session);
}
