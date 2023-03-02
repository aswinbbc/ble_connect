import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubscription;
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;
  List<int> receivedData = [];

  // The service UUID that your BLE device is advertising
  final String serviceUUID = "87B1DE8D-E7CB-4EA8-A8E4-290209522C83";

  // The characteristic UUID that you want to read data from
  final String characteristicUUID = "87b1de8d-e7cb-4ea8-a8e4-290209522c83";

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    // characteristic?.value?.cancel();
    device?.disconnect();
    super.dispose();
  }

  void startScan() {
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name == "ADXTEST") {
        // Stop scanning when the BLE device is found
        scanSubscription?.cancel();
        connectToDevice(scanResult.device);
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();

    // Find the service with the specified UUID
    BluetoothService service =
        services.firstWhere((s) => s.uuid.toString() == serviceUUID);

    // Find the characteristic with the specified UUID in the service
    BluetoothCharacteristic characteristic = service.characteristics
        .firstWhere((c) => c.uuid.toString() == characteristicUUID);

    // Set the characteristic to notify on value changes
    await characteristic.setNotifyValue(true);
    characteristic.value.listen((value) {
      // Handle incoming data here
      setState(() {
        receivedData = value;
      });
    });

    setState(() {
      this.device = device;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter BLE Example"),
      ),
      body: Center(
        child: device != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Device name: ${device!.name}"),
                  Text("Device ID: ${device!.id}"),
                  Text("Received data: ${receivedData.toString()}"),
                ],
              )
            : Text("Device not connected"),
      ),
    );
  }
}
