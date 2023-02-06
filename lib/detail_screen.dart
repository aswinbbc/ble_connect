import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:lottie/lottie.dart';
import 'package:convert/convert.dart';

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
  final List<int> password = [
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
  ]; //000000 to byte
  final _passCode =
      // [245, 15, 0, 4, 95, 59, 54, 56, 52, 55];
      [0xF5, 0x0F, 0x00, 0x04, 0x5F, 0x40, 0x36, 0x38, 0x34, 0x37];

  int? randomKey;
  bool _connected = false;
  List<int> read = [];
  Stream<ConnectionStateUpdate>? _currentConnectionStream;
  StreamSubscription<ConnectionStateUpdate>? listener;
  late final TextEditingController _passController;
  late HexEncoder _hexEncoder;

  String randomCode = '';

  var selectedUser = 0x01;
  @override
  void initState() {
    super.initState();
    _connect();

    _passController = TextEditingController(text: stringHexToAscii());
  }

  void _connect() {
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
              read = [];
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
              Text(
                'connection status: ${_connected ? 'connected' : 'disconnected'}',
                style: TextStyle(fontWeight: FontWeight.w600),
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
              Text(
                randomCode,
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
                  child: const Text('EX-OR'))
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _connect),
    );
  }

  List<int> createXORList() {
    List<int> exorList = [];
    if (randomKey != null) {
      int keyExor = exorWithKey(x: randomKey!);
      List<int> sendingCode = [
        0xf5,
        0x21,
        0x00,
        0x0d,
        0x5f,
        0x1c,
      ];
      exorList = [
        ...sendingCode,
        keyExor,
        ...username.map((e) => exorWithKey(x: e, key: selectedUser)).toList(),
        ...password.map((e) => exorWithKey(x: e, key: selectedUser)).toList()
      ];
    }
    print(exorList);
    return exorList;
  }

  Future<void> requestRandomCode() async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUuid,
        characteristicId: characteristicWriteUuid,
        deviceId: widget.device.id);
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic,
        value: [0xF5, 0x20, 0x00, 0x00, 0x5F, 0x74]);

    return;
  }

  exorWithKey({int x = 0x01, int key = 0x4f}) {
    var r = (x ^ key);
    print(r.toRadixString(16));
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
    print(response);
    setState(() {
      read = response;
    });
    return response;
  }

  Future<void> writePassword() async {
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
    return;
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
