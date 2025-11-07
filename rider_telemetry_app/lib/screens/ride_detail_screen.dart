import 'package:flutter/material.dart';
import '../models/sample.dart';
import '../services/db_service.dart';

class RideDetailScreen extends StatefulWidget {
  final DbService db;
  final int rideId;
  const RideDetailScreen({super.key, required this.db, required this.rideId});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  List<Sample> _samples = [];
  List<Sample> _filtered = [];
  bool _loading = true;
  String _query = '';

  // Summary stats
  double avgAccel = 0.0;
  double avgDecel = 0.0;
  double avgSpeed = 0.0;
  double? startLat, startLon, endLat, endLon;

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Future<void> _loadSamples() async {
    final samples = await widget.db.samplesForRide(widget.rideId, limit: 5000);

    if (samples.isEmpty) {
      setState(() {
        _samples = [];
        _filtered = [];
        _loading = false;
      });
      return;
    }

    // Calculate averages
    double accelSum = 0;
    double decelSum = 0;
    double speedSum = 0;
    int accelCount = 0;
    int decelCount = 0;

    for (var s in samples) {
      if (s.axLong > 0.2) {
        accelSum += s.axLong;
        accelCount++;
      } else if (s.axLong < -0.2) {
        decelSum += s.axLong.abs();
        decelCount++;
      }
      speedSum += s.speedKmh;
    }

    avgAccel = accelCount > 0 ? accelSum / accelCount : 0.0;
    avgDecel = decelCount > 0 ? decelSum / decelCount : 0.0;
    avgSpeed = samples.isNotEmpty ? speedSum / samples.length : 0.0;

    startLat = samples.first.latitude;
    startLon = samples.first.longitude;
    endLat = samples.last.latitude;
    endLon = samples.last.longitude;

    setState(() {
      _samples = samples;
      _filtered = samples;
      _loading = false;
    });
  }

  void _filterSamples(String query) {
    query = query.trim();
    if (query.isEmpty) {
      setState(() => _filtered = _samples);
      return;
    }

    setState(() {
      _filtered = _samples.where((s) {
        final t = s.timestamp.toIso8601String();
        return t.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ride #${widget.rideId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _samples.isEmpty
              ? const Center(child: Text('No samples recorded for this ride.'))
              : Column(
                  children: [
                    _buildDashboard(),
                    const Divider(height: 20, thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search timestamp',
                          hintText: 'Format: HH:MM:SS',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (q) {
                          _query = q;
                          _filterSamples(q);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final s = _filtered[i];
                          final time = s.timestamp.toIso8601String();
                          return ListTile(
                            dense: true,
                            title: Text(time),
                            subtitle: Text(
                              'ax:${s.axLong.toStringAsFixed(2)}  '
                              'ay:${s.ayLat.toStringAsFixed(2)}  '
                              'az:${s.azUp.toStringAsFixed(2)}  '
                              'speed:${s.speedKmh.toStringAsFixed(1)} km/h\n'
                              '(${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)})  '
                              'bearing:${s.bearingDeg.toStringAsFixed(0)}°',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Ride Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metric('Avg Accel', '${avgAccel.toStringAsFixed(2)} m/s²'),
                  _metric('Avg Decel', '${avgDecel.toStringAsFixed(2)} m/s²'),
                  _metric('Avg Speed', '${avgSpeed.toStringAsFixed(2)} km/h'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: _metric('Start (lat,lon)',
                        '${startLat?.toStringAsFixed(4)}, ${startLon?.toStringAsFixed(4)}'),
                  ),
                  Flexible(
                    child: _metric('End (lat,lon)',
                        '${endLat?.toStringAsFixed(4)}, ${endLon?.toStringAsFixed(4)}'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
