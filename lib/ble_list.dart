import 'dart:async';

import 'dart:io' show Platform;

import 'package:location_permissions/location_permissions.dart';
import 'package:ble_connect/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleListScreen extends StatefulWidget {
  BleListScreen({super.key});

  @override
  State<BleListScreen> createState() => _BleListScreenState();
}

class _BleListScreenState extends State<BleListScreen> {
  final flutterReactiveBle = FlutterReactiveBle();

  List<DiscoveredDevice> devices = [];
  late StreamSubscription<DiscoveredDevice> scanner;

  @override
  void initState() {
    super.initState();
    // Platform permissions handling stuff
    permiCheck().then((value) {
      if (value) {
        scanner = flutterReactiveBle.scanForDevices(
            withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
          print(device.name);
          if (device.name.contains('SN:0000056214')) {
            setState(() {
              if (!devices.contains(device)) devices.add(device);
              scanner.cancel();
            });
          }
        }, onError: (e) {
          print('error $e');
        });
      }
    });

    // flutterReactiveBle
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
      appBar: AppBar(title: Text('ble list')),
      body: ListView.builder(
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
                  title: Text(device.name), subtitle: Text(device.toString())),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          scanner.isPaused ? scanner.resume() : scanner.pause();
        },
      ),
    );
  }
}
