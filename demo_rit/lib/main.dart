import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'map_screen.dart'; // ✅ Import your Map Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDifMiBooJhr2ryu4rAqCLYFDCme5VDBSc",
      appId: "1:609420444373:android:c2a6d7c25217d278d6985c",
      messagingSenderId: "609420444373",
      projectId: "gps-tracking-4392e",
    ),

  );

  // 🔥 Test Firestore Connection
  checkFirestoreConnection();

  runApp(MyApp());
}

void checkFirestoreConnection() async {
  try {
    await FirebaseFirestore.instance
        .collection('test')
        .doc('connectionTest')
        .set({
      'status': 'connected',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("✅ Firestore is connected! Data written successfully.");
  } catch (e) {
    print("❌ Firestore connection failed: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Gilroy',),
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // ✅ Set the initial route
      routes: {
        '/': (context) => HomeScreen(), // ✅ Home Screen
        '/map': (context) => MapScreen(), // ✅ Map Screen
      },
    );
  }
}
