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
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
        cardColor: Colors.grey.shade900,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.tealAccent,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
      ),
      home: HomeScreen(db: db, sensor: sensor),
    );
  }
}
