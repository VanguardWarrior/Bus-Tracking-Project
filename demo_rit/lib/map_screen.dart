

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng busLocation = LatLng(9.574794707123845, 76.62050771630925);
  final LatLng ritKottayam = LatLng(9.579302, 76.624130);

  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  BitmapDescriptor? busIcon;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool vibrationDetected = false;
  double accelerationX = 0.0, accelerationY = 0.0, accelerationZ = 0.0;
  String busStatus = "Normal";

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
    initializeNotifications();
    loadCustomMarker();
    fetchBusLocation();
    fetchSensorData();
    fetchPolylineFromFirestore();
    listenForBusAlerts();
  }

  void requestLocationPermission() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
  }

  void initializeNotifications() async {
    var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: androidInitialize);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<BitmapDescriptor> resizeAndLoadMarker(String assetPath, int width, int height) async {
    ByteData data = await rootBundle.load(assetPath);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List resizedImage = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedImage);
  }


  Future<void> loadCustomMarker() async {
    BitmapDescriptor customIcon = await resizeAndLoadMarker("assets/bus_icon.png", 130, 130);
    setState(() {
      busIcon = customIcon;
    });
  }

  void fetchBusLocation() {
    FirebaseFirestore.instance.collection('bustracking').doc('bus1').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        GeoPoint geoPoint = snapshot.get('location') as GeoPoint;
        setState(() {
          busLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
        });
        if (mapController != null) {
          mapController!.animateCamera(CameraUpdate.newLatLng(busLocation));
        }
      }
    });
  }

  void fetchSensorData() {
    FirebaseFirestore.instance.collection('bustracking').doc('bus1').snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic>? sensorData = snapshot.data()?['sensors'];
        if (sensorData != null) {
          setState(() {
            vibrationDetected = sensorData['vibration'] ?? false;
            accelerationX = (sensorData['accelerationX'] as num).toDouble();
            accelerationY = (sensorData['accelerationY'] as num).toDouble();
            accelerationZ = (sensorData['accelerationZ'] as num).toDouble();
          });
        }
      }
    });
  }

  void fetchPolylineFromFirestore() {
    FirebaseFirestore.instance.collection('routes').doc('pampady_to_rit').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        List<LatLng> newPolylineCoordinates = [];
        List<dynamic> points = snapshot.get('polyline');
        for (var point in points) {
          GeoPoint geoPoint = point as GeoPoint;
          newPolylineCoordinates.add(LatLng(geoPoint.latitude, geoPoint.longitude));
        }
        setState(() {
          polylineCoordinates = newPolylineCoordinates;
          _polylines = {
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            )
          };
        });
      }
    });
  }

  void listenForBusAlerts() {
    FirebaseFirestore.instance.collection("bustracking").doc("bus1").snapshots().listen((snapshot) {
      if (snapshot.exists) {
        String status = snapshot.get("status") ?? "Normal";
        setState(() {
          busStatus = status;
        });
        if (status == "Breakdown Detected") {
          showNotification();
        }
      }
    });
  }

  void showNotification() async {
    var androidDetails = const AndroidNotificationDetails(
      "bus_alerts",
      "Bus Safety",
      channelDescription: "Alerts for bus issues",
      importance: Importance.high,
      priority: Priority.high,
    );

    var generalNotificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      "🚨 Bus Alert",
      "Emergency! Check Bus Status.",
      generalNotificationDetails,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController!.animateCamera(CameraUpdate.newLatLngZoom(busLocation, 14.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Tracker"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: busLocation,
              zoom: 14.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId("busLocation"),
                position: busLocation,
                icon: busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              Marker(
                markerId: const MarkerId("ritKottayam"),
                position: ritKottayam,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            polylines: _polylines,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🚨 Status: $busStatus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("🔄 Vibration: $vibrationDetected"),
                  Text("📡 AccelX: $accelerationX"),
                  Text("📡 AccelY: $accelerationY"),
                  Text("📡 AccelZ: $accelerationZ"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}