import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/sensor_service.dart';
import 'rides_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final DbService db;
  final SensorService sensor;
  const HomeScreen({super.key, required this.db, required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Telemetry')),
      body: const Center(
        child: Text('Welcome! Track your rides with calibrated sensors.', textAlign: TextAlign.center),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RidesListScreen(db: db, sensor: sensor),
              ));
            },
            child: const Text('My Rides'),
          ),
        ),
      ),
    );
  }
}
