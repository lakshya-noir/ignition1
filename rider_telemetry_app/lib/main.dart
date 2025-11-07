import 'package:flutter/material.dart';
import 'services/db_service.dart';
import 'services/sensor_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DbService();
  await db.init();
  final sensor = SensorService(db);
  runApp(App(db: db, sensor: sensor));
}

class App extends StatelessWidget {
  final DbService db;
  final SensorService sensor;
  const App({super.key, required this.db, required this.sensor});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rider Telemetry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: HomeScreen(db: db, sensor: sensor),
    );
  }
}
