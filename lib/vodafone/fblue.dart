import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({super.key});

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  final serviceUuid = "87B1DE8DE7CB4EA8A8E4290209522C83";
  final NOTIFICATION_DESCRIPTOR_UUID = "0000290200001000800000805f9b34fb";

  final NEDAP_READER_SERVICE_UUID = "87b1de8de7cb4ea8a8e4290209522c83";
  final NEDAP_READER_CHARACTERISTIC = "e68a5c09aef844478f10f3339898dee9";

  final MACE_CHALLENGE = "540810c2d57311e5ab30625662870761";
  final MACE_CHALLENGE_RESPONSE = "54080bd6d57311e5ab30625662870761";
  ScanResult? result;
  @override
  void initState() {
    super.initState();
    // Start scanning
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
      // do something with scan results
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
        if (r.device.name.contains("ADXTEST")) {
          setState(() {
            result = r;
          });
          // Stop scanning
          flutterBlue.stopScan();
        }
      }
    });
  }

  @override
  void dispose() {
    flutterBlue.stopScan();
    super.dispose();
  }

  var btnTitle = 'connect';
  var data = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Card(
        child: ListTile(
          title: Text(result?.device.name ?? "scanning"),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text((result?.rssi ?? 0).toString()),
              Text(data),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(onPressed: connect, child: Text(btnTitle)),
                  ElevatedButton(
                      onPressed: disconnect, child: Text("disconnect")),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }

  connect() async {
    // Connect to the device
    await result?.device.connect();
    result?.device.isDiscoveringServices.asBroadcastStream(
      onListen: (subscription) {
        setState(() {
          btnTitle = subscription.isPaused.toString();
        });
      },
    );
    discoverServices();
  }

  discoverServices() async {
    if (result != null) {
      data = '';
      List<BluetoothService> services = await result!.device.discoverServices();
      services.forEach((service) {
        data += service.uuid.toString();
      });
      setState(() {});
    }
  }

  void disconnect() {
    result?.device.disconnect();
  }
}
