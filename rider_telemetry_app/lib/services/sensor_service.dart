import 'dart:async';
import 'dart:math';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sample.dart';
import 'db_service.dart';

class SensorService {
  final DbService db;
  final _sampleCtrl = StreamController<Sample>.broadcast();
  Stream<Sample> get stream => _sampleCtrl.stream;

  // subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;        // includes gravity
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub; // linear accel
  StreamSubscription<Position>? _gpsSub;

  // gravity estimate (low-pass)
  vm.Vector3 _g = vm.Vector3(0, 0, 9.81);
  final double _alpha = 0.90; // LPF for gravity

  // latest readings
  vm.Vector3 _linAccDev = vm.Vector3.zero(); // device frame linear accel
  double _speedKmh = 0.0;
  double _bearingDeg = 0.0;
  double _lat = 0.0, _lon = 0.0;

  // deceleration (from speed delta)
  double _lastSpeedKmh = 0.0;
  DateTime _lastSpeedTime = DateTime.now();

  int? _currentRideId;

  SensorService(this.db);

  bool get isRunning => _currentRideId != null;

  Future<void> startRide() async {
    if (_currentRideId != null) return;
    _currentRideId = await db.createRide();

    // Accelerometer (with gravity) to estimate orientation
    _accelSub = accelerometerEvents.listen((e) {
      // Low-pass to get gravity
      _g = vm.Vector3(
        _alpha * _g.x + (1 - _alpha) * e.x,
        _alpha * _g.y + (1 - _alpha) * e.y,
        _alpha * _g.z + (1 - _alpha) * e.z,
      );
    });

    // Linear acceleration in device frame (gravity removed)
    _userAccelSub = userAccelerometerEvents.listen((e) {
      _linAccDev = vm.Vector3(e.x, e.y, e.z);
      _emitSampleIfPossible();
    });

    // GPS
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((pos) {
      final now = DateTime.now();
      final dt = max(1e-6, now.difference(_lastSpeedTime).inMilliseconds / 1000.0);
      final curKmh = pos.speed * 3.6;
      _bearingDeg = pos.heading.isNaN ? _bearingDeg : pos.heading; // 0..360, 0 north
      _speedKmh = curKmh;
      _lat = pos.latitude;
      _lon = pos.longitude;

      _lastSpeedTime = now;
      _lastSpeedKmh = curKmh;

      _emitSampleIfPossible();
    });
  }

  Future<void> stopRide() async {
    await _accelSub?.cancel();
    await _userAccelSub?.cancel();
    await _gpsSub?.cancel();
    _accelSub = null;
    _userAccelSub = null;
    _gpsSub = null;

    if (_currentRideId != null) {
      await db.endRide(_currentRideId!);
      _currentRideId = null;
    }
  }

  void dispose() {
    _sampleCtrl.close();
  }

  // ---------------- internal helpers ----------------

  void _emitSampleIfPossible() {
    final rideId = _currentRideId;
    if (rideId == null) return;

    // Build rotation to align device frame to world/vehicle frame

    // 1) Up vector from gravity (device -> world tilt)
    var g = _g.length2 > 0 ? _g : vm.Vector3(0, 0, 9.81);
    final up = (-g).normalized(); // up is opposite gravity

    // 2) Heading from GPS (degrees clockwise from North)
    final headRad = (_bearingDeg) * pi / 180.0;
    // World basis (ENU): x=East, y=North, z=Up
    final forwardWorld = vm.Vector3(sin(headRad), cos(headRad), 0).normalized();
    final leftWorld = up.cross(forwardWorld).normalized(); // left
    final correctedForward = leftWorld.cross(up).normalized(); // re-orthogonalize

    // 3) We need to rotate device linear acceleration into world basis.
    // Without full rotation matrix from sensors, we approximate by decomposing
    // using device tilt (up) and assuming yaw aligns with GPS heading.
    //
    // Compute pitch/roll-only rotation (device->world ignoring yaw)
    // Device axes: +X right, +Y up, +Z out of screen typically (depends on phone)
    // We'll construct a matrix that maps device Z to -up and keeps horizontal plane.
    final zDev = vm.Vector3(0, 0, 1);
    final axis = zDev.cross(-up);
    final angle = acos(max(-1.0, min(1.0, zDev.dot(-up))));
    vm.Quaternion qTilt;
    if (axis.length2 < 1e-6 || angle.abs() < 1e-6) {
      qTilt = vm.Quaternion.identity();
    } else {
      qTilt = vm.Quaternion.axisAngle(axis.normalized(), angle);
    }
    final rotTilt = vm.Matrix3.zero();
    qTilt.copyRotationInto(rotTilt);
    final laTilted = rotTilt * _linAccDev;

    // Now align yaw: world X/Y axes to heading (forwardWorld/leftWorld)
    // Project onto forward/left/up world basis
    final axLong = laTilted.dot(correctedForward);
    final ayLat  = laTilted.dot(leftWorld);
    final azUp   = laTilted.dot(up);

    final s = Sample(
      rideId: rideId,
      timestamp: DateTime.now(),
      axLong: axLong,
      ayLat: ayLat,
      azUp: azUp,
      ax: _linAccDev.x,
      ay: _linAccDev.y,
      az: _linAccDev.z,
      speedKmh: _speedKmh,
      latitude: _lat,
      longitude: _lon,
      bearingDeg: _bearingDeg,
    );

    _sampleCtrl.add(s);
    db.insertSample(s);
  }
}
