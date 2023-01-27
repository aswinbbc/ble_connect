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
  late QualifiedCharacteristic _rxCharacteristic;

  @override
  void initState() {
    super.initState();
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
                                value: [0x00]);
                      },
                      child: const Text('Write pass')),
                  ElevatedButton(
                      onPressed: () async {
                        final characteristic = QualifiedCharacteristic(
                            serviceId: serviceUuid,
                            characteristicId: characteristicReadUuid,
                            deviceId: widget.device.id);
                        await flutterReactiveBle.readCharacteristic(
                          characteristic,
                        );
                      },
                      child: const Text('Read')),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Stream<ConnectionStateUpdate> _currentConnectionStream =
              flutterReactiveBle.connectToAdvertisingDevice(
                  id: widget.device.id,
                  prescanDuration: const Duration(seconds: 1),
                  withServices: [serviceUuid]);
          _currentConnectionStream.listen((event) {
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
                  break;
                }
              default:
            }
          }, onError: (error) {
            // Handle a possible error
            print(error);
          });
        },
      ),
    );
  }
}
