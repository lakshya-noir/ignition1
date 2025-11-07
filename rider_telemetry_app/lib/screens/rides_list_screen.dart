import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/db_service.dart';
import '../services/sensor_service.dart';
import 'ride_record_screen.dart';
import 'ride_detail_screen.dart';

class RidesListScreen extends StatefulWidget {
  final DbService db;
  final SensorService sensor;
  const RidesListScreen({super.key, required this.db, required this.sensor});

  @override
  State<RidesListScreen> createState() => _RidesListScreenState();
}

class _RidesListScreenState extends State<RidesListScreen> {
  late Future<List<Ride>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.db.listRides();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.db.listRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Rides')),
      body: FutureBuilder<List<Ride>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rides = snap.data!;
          if (rides.isEmpty) {
            return const Center(child: Text('No rides yet. Tap + to start one.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: rides.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = rides[i];
                final title = r.endTime == null
                    ? 'Ride #${r.id} (in progress)'
                    : 'Ride #${r.id}';
                final subtitle = r.endTime == null
                    ? 'Started: ${r.startTime}'
                    : 'Start: ${r.startTime}\nEnd:   ${r.endTime}';
                return ListTile(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: Text('${r.sampleCount} samples'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RideDetailScreen(db: widget.db, rideId: r.id),
                    ));
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RideRecordScreen(db: widget.db, sensor: widget.sensor),
          ));
          _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Ride'),
      ),
    );
  }
}
