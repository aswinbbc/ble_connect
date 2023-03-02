import 'dart:async';

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:ble_connect/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:lottie/lottie.dart';

class BleListScreen extends StatefulWidget {
  const BleListScreen({super.key});

  @override
  State<BleListScreen> createState() => _BleListScreenState();
}

class _BleListScreenState extends State<BleListScreen> {
  final flutterReactiveBle = FlutterReactiveBle();

  List<DiscoveredDevice> devices = [];
  late StreamSubscription<DiscoveredDevice> scanner;

  var isNotFound = true;

  @override
  void initState() {
    super.initState();
    // Platform permissions handling stuff
    permiCheck().then((value) {
      if (value) {
        search();
      }
    });

    // flutterReactiveBle
  }

  search() {
    setState(() {
      devices = [];
      isNotFound = true;
    });
    scanner = flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      if (kDebugMode) {
        print(device.name);
      }
      if (device.name.contains('ADXTEST')) {
        setState(() {
          if (!devices.contains(device)) devices.add(device);
          scanner.cancel();
          isNotFound = false;
        });
      }
    }, onError: (e) {
      if (kDebugMode) {
        print('error $e');
      }
    });
  }

  Future<bool> permiCheck() async {
    // Platform permissions handling stuff
    bool permGranted = false;

    PermissionStatus permission;
    if (Platform.isAndroid) {
      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }
    return permGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ble list')),
      body: Column(
        children: [
          Lottie.asset('assets/bluetooth.json', animate: isNotFound),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                var device = devices[index];
                return Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(device: device),
                          ));
                    },
                    child: ListTile(
                        title: Text(device.name),
                        subtitle: Text(device.toString())),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          search();
        },
      ),
    );
  }
}
