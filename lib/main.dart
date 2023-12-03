import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:weatherapp/bloc/weather_bloc_bloc.dart';
import 'package:weatherapp/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _determinePosition(),
        builder: (context, snap) {
          if (snap.hasData) {
            return BlocProvider<WeatherBlocBloc>(
              create: (context) => WeatherBlocBloc()
                ..add(
                  FetchWeather(snap.data as Position),
                ),
              child: const HomeScreen(),
            );
          } else {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}

//This is the methode to determine the position of the user
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  PermissionStatus permissionStatus;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permissionStatus = await Permission.location.status;
  if (permissionStatus == PermissionStatus.denied) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 31) {
      // Request background location permission for Android 12 and later
      permissionStatus = await Permission.locationAlways.request();
    } else {
      // Request regular location permission for older Android versions
      permissionStatus = await Permission.locationWhenInUse.request();
    }

    if (permissionStatus == PermissionStatus.denied) {
      //Return this if the user location is denied
      return Future.error('Location permissions are denied');
    }
  }

  if (permissionStatus == PermissionStatus.permanentlyDenied) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  return await Geolocator.getCurrentPosition();
}
