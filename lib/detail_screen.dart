import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.device});
  final DiscoveredDevice device;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final flutterReactiveBle = FlutterReactiveBle();
  final Uuid serviceUuid = Uuid.parse("0000fff0-0000-1000-8000-00805f9b34fb");
  final Uuid characteristicWriteUuid =
      Uuid.parse("0000fff2-0000-1000-8000-00805f9b34fb");
  final Uuid characteristicReadUuid =
      Uuid.parse("0000fff1-0000-1000-8000-00805f9b34fb");
  bool _connected = false;
  Stream<ConnectionStateUpdate>? _currentConnectionStream;
  StreamSubscription<ConnectionStateUpdate>? listener;
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    if (_currentConnectionStream != null) {
      listener!.cancel();
      _currentConnectionStream = null;
      listener = null;
    }
    _currentConnectionStream = flutterReactiveBle.connectToAdvertisingDevice(
        id: widget.device.id,
        // prescanDuration: const Duration(seconds: 1),
        prescanDuration: const Duration(seconds: 1),
        withServices: [serviceUuid, characteristicWriteUuid]);
    listener = _currentConnectionStream!.listen((event) {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            setState(() {
              // _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
            break;
          }
        // Can add various state state updates on disconnect
        case DeviceConnectionState.disconnected:
          {
            setState(() {
              // _foundDeviceWaitingToConnect = false;
              _connected = false;
            });
            break;
          }
        default:
      }
    }, onError: (error) {
      // Handle a possible error
      print('error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.device.toString()),
              Text('connection $_connected'),
              Row(
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        final characteristic = QualifiedCharacteristic(
                            serviceId: serviceUuid,
                            characteristicId: characteristicWriteUuid,
                            deviceId: widget.device.id);
                        await flutterReactiveBle
                            .writeCharacteristicWithResponse(characteristic,
                                //F5 0F 00 04 5F 3B 36 38 34 37
                                value: [
                              0xF5,
                              0x0F,
                              0x00,
                              0x04,
                              0x5F,
                              0x3B,
                              0x36,
                              0x38,
                              0x34,
                              0x37
                            ]);
                      },
                      child: const Text('Write pass')),
                  ElevatedButton(
                      onPressed: () async {
                        final characteristic = QualifiedCharacteristic(
                            serviceId: serviceUuid,
                            characteristicId: characteristicReadUuid,
                            deviceId: widget.device.id);
                        var response =
                            await flutterReactiveBle.readCharacteristic(
                          characteristic,
                        );
                        print(response
                            .map((e) => e.toRadixString(16).padLeft(2, '0'))
                            .toList());
                      },
                      child: const Text('Read')),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _connect),
    );
  }
}
