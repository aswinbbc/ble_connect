import 'dart:async';

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
  final Uuid serviceUuid = Uuid.parse("0000fff0-0000-1000-8000-00805f9b34fb");
  final Uuid characteristicWriteUuid =
      Uuid.parse("0000fff2-0000-1000-8000-00805f9b34fb");
  final Uuid characteristicReadUuid =
      Uuid.parse("0000fff1-0000-1000-8000-00805f9b34fb");
  final List<int> username = [
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
  List<int> exorList = [];
  final List<int> password = [
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
  ]; //000000 to byte

  int? randomKey;
  bool _connected = false;
  List<int> read = [];
  Stream<ConnectionStateUpdate>? _currentConnectionStream;
  StreamSubscription<ConnectionStateUpdate>? listener;

  String randomCode = '';

  var selectedUser = 0x01;
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
    Map<Uuid, List<Uuid>>? serviceChar = {
      serviceUuid: [characteristicReadUuid, characteristicWriteUuid]
    };

    // _currentConnectionStream = flutterReactiveBle.connectToAdvertisingDevice(
    //     id: widget.device.id,
    //     // prescanDuration: const Duration(seconds: 1),
    //     prescanDuration: const Duration(seconds: 1),
    //     withServices: [serviceUuid, characteristicWriteUuid]);

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
                  writePassword().then((value) => readResponse());
                },
                child: const Text('Pair with Password',
                    style: TextStyle(fontSize: 20)),
              ),
              ElevatedButton(
                onPressed: () {
                  requestRandomCode()
                      .then((value) => readResponse().then((value) {
                            setState(() {
                              randomKey = value.last;
                              randomCode =
                                  "Random Code : {ascii: ${String.fromCharCodes([
                                    value.last,
                                    value[value.length - 2]
                                  ])}    #HEX : ${value[value.length - 2].toRadixString(16)},${value.last.toRadixString(16)} }";
                            });
                          }));
                },
                child: const Text('Request Random Code',
                    style: TextStyle(fontSize: 20)),
              ),
              SelectableText(
                (randomKey ?? 0).toRadixString(16),
                style: const TextStyle(fontSize: 25),
              ),
              RadioListTile(
                value: 0x01,
                groupValue: selectedUser,
                onChanged: (ind) => setState(() => selectedUser = ind!),
                title: const Text("admin"),
              ),
              RadioListTile(
                value: 0x02,
                groupValue: selectedUser,
                onChanged: (ind) => setState(() => selectedUser = ind!),
                title: const Text("user"),
              ),
              RadioListTile(
                value: 0x04,
                groupValue: selectedUser,
                onChanged: (ind) => setState(() => selectedUser = ind!),
                title: const Text("one time user"),
              ),
              ElevatedButton(
                  onPressed: () {
                    createXORList();
                  },
                  child: const Text('Create EX-OR List')),
              SelectableText('${intListToHexStringList(exorList)}'),

              ElevatedButton(
                  onPressed: () {
                    sendXORList().then((value) => readResponse());
                  },
                  child: const Text('Send EX-OR List')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _connect),
    );
  }

  List<int> createXORList() {
    // randomKey = 0xB3;
    List<int> exorList = [];
    late int sixthByte;
    if (randomKey != null) {
      int keyExor = exorWithKey(x: selectedUser, key: randomKey!);
      List<int> sendingCode = [
        0xf5,
        0x21,
        0x00,
        0x0d,
        0x5f,
        //0x1c,
      ];
      final xorUsername =
          username.map((e) => exorWithKey(x: e, key: randomKey!)).toList();
      final xorPassword =
          password.map((e) => exorWithKey(x: e, key: randomKey!)).toList();

      // /add 1 st byte to 5 and 7 till 19 th byte after xor operation
      sixthByte = (sendingCode.reduce((a, b) => a + b)) +
          keyExor +
          (xorUsername.reduce((a, b) => a + b)) +
          (xorPassword.reduce((a, b) => a + b));

      // ///add 1 st byte to 5 and 7 till 19 th byte before xor operation
      // sixthByte = (sendingCode.reduce((a, b) => a + b)) +
      //     selectedUser +
      //     (username.reduce((a, b) => a + b)) +
      //     (password.reduce((a, b) => a + b));
      exorList = [
        ...sendingCode,
        sixthByte,
        keyExor,
        ...xorUsername,
        ...xorPassword,
      ];
    }
    if (kDebugMode) {
      print(exorList);
    }
    setState(() {
      this.exorList = exorList;
    });
    if (kDebugMode) {
      print(intListToHexStringList(exorList));
    }
    return exorList;
  }

  Future<int> sendXORList() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicWriteUuid,
        deviceId: widget.device.id);
    var hexList =
        (intListToHexStringList(exorList).map((e) => int.parse(e)).toList());
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: hexList);

    return 1;
  }

  List<String> intListToHexStringList(List<int> intList) {
    List<String> hexStringList = [];
    for (int decimal in intList) {
      String hexString =
          '0x${decimal.toRadixString(16).padLeft(2, '0').toUpperCase()}';
      hexStringList.add(hexString);
    }
    return hexStringList;
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

  int exorWithKey({int x = 0x01, int key = 0x4f}) {
    // key = 0x4f;
    // key = int.parse('b3', radix: 16);
    var r = (x ^ key);

    return r;
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

  Future<int> writePassword() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicWriteUuid,
        deviceId: widget.device.id);
    //[0xF5,0x0F,0x00,0x04,0x5F,0x3B,0x36,0x38,0x34,0x37]
    //F5 0F 00 04 5F 3B 36 38 34 37
    //245 15  0  4  95  59  54  56  52  55

    //utf8.encode('õ_;6847')
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: [0xF5, 0x0F, 0x00, 0x04, 0x5F, 0x40, 0x36, 0x38, 0x34, 0x37]);
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
