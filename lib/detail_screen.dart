import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.device});
  final DiscoveredDevice device;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final flutterReactiveBle = FlutterReactiveBle();
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          flutterReactiveBle
              .connectToAdvertisingDevice(
            id: widget.device.id,
            withServices: [Uuid.parse('0000fff0-0000-1000-8000-00805f9b34fb')],
            prescanDuration: const Duration(seconds: 5),
            // servicesWithCharacteristicsToDiscover: {serviceId: [char1, char2]},
            connectionTimeout: const Duration(seconds: 2),
          )
              .listen((connectionState) {
            // Handle connection state updates
          }, onError: (dynamic error) {
            // Handle a possible error
          });
        },
      ),
    );
  }
}
