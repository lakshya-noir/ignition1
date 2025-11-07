import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        final t = DateFormat.Hms().format(s.timestamp);
        return t.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.Hms();

    return Scaffold(
      appBar: AppBar(
        title: Text('Ride #${widget.rideId}'),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _samples.isEmpty
              ? const Center(child: Text('No samples recorded for this ride.'))
              : Column(
                  children: [
                    _buildDashboard(),
                    const Divider(height: 20, thickness: 0.8, color: Colors.grey),
                    // --- Search bar ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Search timestamp',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Format: HH:MM:SS',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.tealAccent),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: Colors.grey.shade800, width: 1),
                          ),
                        ),
                        onChanged: (q) {
                          _query = q;
                          _filterSamples(q);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // --- Timestamped samples ---
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final s = _filtered[i];
                          final ts = timeFmt.format(s.timestamp);

                          return Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timestamp
                                Text(
                                  ts,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Acceleration
                                Text(
                                  'Accel (x,y,z):  ${s.axLong.toStringAsFixed(2)}, '
                                  '${s.ayLat.toStringAsFixed(2)}, '
                                  '${s.azUp.toStringAsFixed(2)} m/s²',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                // Speed and bearing
                                Text(
                                  'Speed: ${s.speedKmh.toStringAsFixed(2)} km/h   '
                                  'Bearing: ${s.bearingDeg.toStringAsFixed(0)}°',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                // Coordinates
                                Text(
                                  'Location: (${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)})',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // ------------------ Dashboard (Summary Card) ------------------
  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 3,
        color: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Ride Summary',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent)),
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
                    child: _metric(
                        'Start (lat,lon)',
                        '${startLat?.toStringAsFixed(4)}, '
                        '${startLon?.toStringAsFixed(4)}'),
                  ),
                  Flexible(
                    child: _metric(
                        'End (lat,lon)',
                        '${endLat?.toStringAsFixed(4)}, '
                        '${endLon?.toStringAsFixed(4)}'),
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
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white)),
      ],
    );
  }
}
