import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/db_service.dart';
import '../services/sensor_service.dart';
import 'ride_detail_screen.dart';
import 'ride_record_screen.dart'; // ✅ correct file name

class HomeScreen extends StatefulWidget {
  final DbService db;
  final SensorService sensor;
  const HomeScreen({super.key, required this.db, required this.sensor});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Ride> rides = [];

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    final data = await widget.db.listRides();
    setState(() => rides = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Telemetry 🚴‍♂️'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: rides.isEmpty
            ? const Center(
                child: Text(
                  'No rides recorded yet.\nTap + to start your first ride!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: rides.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = rides[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideDetailScreen(
                          db: widget.db,
                          rideId: r.id,
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ride #${r.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Samples: ${r.sampleCount ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white70),
                                ),
                                Text(
                                  'Date: ${r.startTime ?? 'Unknown'}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54),
                                ),
                              ]),
                          const Icon(Icons.chevron_right,
                              color: Colors.tealAccent)
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Ride'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideRecordScreen( // ✅ correct class name
                db: widget.db,
                sensor: widget.sensor,
              ),
            ),
          );
          _loadRides(); // refresh after returning
        },
      ),
    );
  }
}
