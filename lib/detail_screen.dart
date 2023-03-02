import 'dart:async';
import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:lottie/lottie.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.device});
  final DiscoveredDevice device;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final flutterReactiveBle = FlutterReactiveBle();
  final Uuid serviceUuid = Uuid.parse("87B1DE8D-E7CB-4EA8-A8E4-290209522C83");
  final Uuid characteristicWriteUuid =
      Uuid.parse("0000fff2-0000-1000-8000-00805f9b34fb");
  final Uuid characteristicReadUuid =
      Uuid.parse("E68A5C09-AEF8-4447-8F10-F3339898DEE9");

  final NOTIFICATION_DESCRIPTOR_UUID =
      Uuid.parse("00002902-0000-1000-8000-00805f9b34fb");

  final NEDAP_READER_SERVICE_UUID =
      Uuid.parse("87b1de8d-e7cb-4ea8-a8e4-290209522c83");
  final NEDAP_READER_CHARACTERISTIC =
      Uuid.parse("e68a5c09-aef8-4447-8f10-f3339898dee9");

  final MACE_CHALLENGE = Uuid.parse("540810c2-d573-11e5-ab30-625662870761");
  final MACE_CHALLENGE_RESPONSE =
      Uuid.parse("54080bd6-d573-11e5-ab30-625662870761");

  bool _connected = false;
  List<int> read = [];
  Stream<ConnectionStateUpdate>? _currentConnectionStream;
  StreamSubscription<ConnectionStateUpdate>? listener;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    if (_connected) {
      readResponse();
      return;
    }
    if (_currentConnectionStream != null) {
      listener!.cancel();
      _currentConnectionStream = null;
      listener = null;
    }

    // _currentConnectionStream = flutterReactiveBle.connectToAdvertisingDevice(
    //     id: widget.device.id,
    //     // prescanDuration: const Duration(seconds: 1),
    //     prescanDuration: const Duration(seconds: 1),
    //     withServices: [serviceUuid, characteristicReadUuid]);

    Map<Uuid, List<Uuid>>? serviceChar = {
      serviceUuid: [characteristicReadUuid, characteristicWriteUuid]
    };
    _currentConnectionStream = flutterReactiveBle.connectToDevice(
        id: widget.device.id,
        servicesWithCharacteristicsToDiscover: serviceChar);

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
              // read = [];
            });
            break;
          }
        default:
      }
    }, onError: (error) {
      // Handle a possible error
      if (kDebugMode) {
        print('error: $error');
      }
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
              Text(
                'connection status: ${_connected ? 'connected' : 'disconnected'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Lottie.asset(
                  _connected ? "assets/bluetooth.json" : "assets/cat.json",
                  height: 65),
              Text(widget.device.toString()),
              Text('response :${hex.encode(read)}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              // TextField(controller: _passController),
              ElevatedButton(
                onPressed: () {
                  readResponse();
                  // writePassword().then((value) => readResponse());
                },
                child: const Text('A->B(UUID-ID):UIDA',
                    style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _connect),
    );
  }

  Future<int> requestRandomCode() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicWriteUuid,
        deviceId: widget.device.id);
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: [0xF5, 0x20, 0x00, 0x00, 0x5F, 0x74]);

    return 1;
  }

  Future<List<int>> readResponse() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicReadUuid,
        deviceId: widget.device.id);
    var response = await flutterReactiveBle.readCharacteristic(
      characteristic,
    );
    if (kDebugMode) {
      print(response);
    }
    setState(() {
      if (kDebugMode) {
        print(hex.encode(read));
      }
      read = response;
    });
    return response;
  }

  Future<int> sendAtoB_UUID_ID() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: NEDAP_READER_CHARACTERISTIC,
        deviceId: widget.device.id);
    final response =
        await flutterReactiveBle.readCharacteristic(characteristic);
    log(response.toString());
    // final characteristic = QualifiedCharacteristic(
    //     serviceId: serviceUuid,
    //     characteristicId: characteristicReadUuid,
    //     deviceId: widget.device.id);
    // await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
    //     value: [0xF5, 0x0F, 0x00, 0x04, 0x5F, 0x40, 0x36, 0x38, 0x34, 0x37]);
    // await flutterReactiveBle
    //     .writeCharacteristicWithResponse(characteristic,
    //         value: [245, 15, 0, 4, 95, 59, 54, 56, 52, 55]);
    return 1;
  }

  String stringHexToAscii() {
    String hexString = "F50F00045F3B36383437";
    List<String> splitted = [];
    for (int i = 0; i < hexString.length; i = i + 2) {
      splitted.add(hexString.substring(i, i + 2));
    }
    String ascii = List.generate(splitted.length,
        (i) => String.fromCharCode(int.parse(splitted[i], radix: 16))).join();
    return ascii;
  }
}
