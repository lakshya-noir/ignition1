import 'dart:async';
import 'package:flutter/material.dart';
import 'models/telemetry_model.dart';
import 'services/db_service.dart';
import 'services/sensor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Telemetry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const TelemetryScreen(),
    );
  }
}

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final db = DbService();
  late final SensorService sensor;

  StreamSubscription<Telemetry>? sub;
  Telemetry? last;
  int saved = 0;
  bool running = false;

  @override
  void initState() {
    super.initState();
    sensor = SensorService(db);
    _init();
  }

  Future<void> _init() async {
    await db.init();
    saved = await db.count();
    setState(() {});
  }

  Future<void> _start() async {
    if (running) return;
    await sensor.start();
    sub = sensor.stream.listen((t) async {
      setState(() => last = t);
    });
    running = true;
    setState(() {});
    // Periodically refresh saved count
    Timer.periodic(const Duration(seconds: 2), (tmr) async {
      if (!running) {
        tmr.cancel();
        return;
      }
      saved = await db.count();
      if (mounted) setState(() {});
    });
  }

  Future<void> _stop() async {
    running = false;
    await sub?.cancel();
    sensor.stop(); // no await here — stop() is synchronous
    saved = await db.count();
    setState(() {});
  }

  @override
  void dispose() {
    sub?.cancel();
    sensor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = last;
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Telemetry 🚴‍♂️')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _card('Speed', '${(t?.speed ?? 0).toStringAsFixed(2)} km/h'),
            _card('|Acceleration|', '${(t?.accelMag ?? 0).toStringAsFixed(2)} m/s²'),
            _card('Accel X', '${(t?.accelX ?? 0).toStringAsFixed(2)}'),
            _card('Accel Y', '${(t?.accelY ?? 0).toStringAsFixed(2)}'),
            _card('Accel Z', '${(t?.accelZ ?? 0).toStringAsFixed(2)}'),
            _card('GPS', '${(t?.latitude ?? 0).toStringAsFixed(6)}, ${(t?.longitude ?? 0).toStringAsFixed(6)}'),
            const SizedBox(height: 12),
            _card('Saved samples', '$saved'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: running ? null : _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Recording'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: running ? _stop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
