class Sample {
  final int? id;
  final int rideId;
  final DateTime timestamp;

  // Vehicle/world-aligned acceleration (m/s^2)
  final double axLong; // forward/back
  final double ayLat;  // left/right
  final double azUp;   // up/down

  // Raw device linear acceleration (optional debug)
  final double ax;
  final double ay;
  final double az;

  // GPS
  final double speedKmh;
  final double latitude;
  final double longitude;
  final double bearingDeg;

  Sample({
    this.id,
    required this.rideId,
    required this.timestamp,
    required this.axLong,
    required this.ayLat,
    required this.azUp,
    required this.ax,
    required this.ay,
    required this.az,
    required this.speedKmh,
    required this.latitude,
    required this.longitude,
    required this.bearingDeg,
  });

  Map<String, dynamic> toMap() => {
    'ride_id': rideId,
    'timestamp': timestamp.toIso8601String(),
    'ax_long': axLong,
    'ay_lat': ayLat,
    'az_up': azUp,
    'ax': ax,
    'ay': ay,
    'az': az,
    'speed_kmh': speedKmh,
    'lat': latitude,
    'lon': longitude,
    'bearing_deg': bearingDeg,
  };

  factory Sample.fromMap(Map<String, dynamic> m) => Sample(
    id: m['id'] as int?,
    rideId: m['ride_id'] as int,
    timestamp: DateTime.parse(m['timestamp'] as String),
    axLong: (m['ax_long'] as num).toDouble(),
    ayLat: (m['ay_lat'] as num).toDouble(),
    azUp: (m['az_up'] as num).toDouble(),
    ax: (m['ax'] as num).toDouble(),
    ay: (m['ay'] as num).toDouble(),
    az: (m['az'] as num).toDouble(),
    speedKmh: (m['speed_kmh'] as num).toDouble(),
    latitude: (m['lat'] as num).toDouble(),
    longitude: (m['lon'] as num).toDouble(),
    bearingDeg: (m['bearing_deg'] as num).toDouble(),
  );
}
