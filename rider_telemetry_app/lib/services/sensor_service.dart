import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/telemetry_model.dart';
import 'db_service.dart';

class SensorService {
  final DbService db;
  final _telemetryController = StreamController<Telemetry>.broadcast();

  Stream<Telemetry> get stream => _telemetryController.stream;

  late StreamSubscription<AccelerometerEvent> _accelSub;
  late StreamSubscription<Position> _gpsSub;

  double _lastSpeed = 0.0;
  DateTime _lastTime = DateTime.now();

  SensorService(this.db);

  Future<void> start() async {
    // Start accelerometer listener
    _accelSub = accelerometerEvents.listen((event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      final telemetry = Telemetry(
        timestamp: DateTime.now(),
        accelX: event.x,
        accelY: event.y,
        accelZ: event.z,
        accelMag: magnitude, // ✅ added this field
        speed: _lastSpeed,
        latitude: 0.0,
        longitude: 0.0,
      );

      _telemetryController.add(telemetry);
      db.insertTelemetry(telemetry); // store locally
    });

    // Start GPS listener
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      double speedKmh = pos.speed * 3.6;
      double decel = 0.0;

      DateTime now = DateTime.now();
      double deltaTime = now.difference(_lastTime).inMilliseconds / 1000.0;
      if (deltaTime > 0) decel = (_lastSpeed - speedKmh) / deltaTime;

      _lastSpeed = speedKmh;
      _lastTime = now;

      final telemetry = Telemetry(
        timestamp: now,
        accelX: 0.0,
        accelY: 0.0,
        accelZ: 0.0,
        accelMag: 0.0,
        speed: speedKmh,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      _telemetryController.add(telemetry);
      db.insertTelemetry(telemetry);
    });
  }

  void stop() {
    _accelSub.cancel();
    _gpsSub.cancel();
  }

  void dispose() {
    _telemetryController.close();
  }
}
