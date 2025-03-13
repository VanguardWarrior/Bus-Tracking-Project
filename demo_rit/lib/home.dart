import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // For animations
import 'map_screen.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String? selectedRoute;
  String? selectedBus;

  final Map<String, List<String>> busRoutes = {
    'RIT <----> Pala': ['Bus 1', 'Bus 2', 'Bus 3'],
    'RIT <----> Kottayam': ['Bus 4', 'Bus 5', 'Bus 6'],
    'RIT <----> Ettumanoor': ['Bus 7', 'Bus 8', 'Bus 9'],
  };

  late AnimationController _animationController;
  late Animation<double> _busImageAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _busImageAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeInDown(
          child: Text("Bus Tracker",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        backgroundColor: const Color.fromARGB(255, 47, 168, 244),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Lottie.asset(
              // Replace Image.asset with Lottie.asset
              'assets/bus.json',
              height: 180,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 40),
            FadeInUp(
              delay: Duration(milliseconds: 200),
              child: Text("Select Route",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 47, 168, 244),
                  )),
            ),
            SizedBox(height: 15),
            FadeInUp(
              delay: Duration(milliseconds: 300),
              child: DropdownButtonFormField<String>(
                value: selectedRoute,
                hint: Text("Choose a Route"),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.indigo.shade50,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                items: busRoutes.keys.map((route) {
                  return DropdownMenuItem<String>(
                    value: route,
                    child: Text(route),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRoute = value;
                    selectedBus = null;
                  });
                },
              ),
            ),
            SizedBox(height: 30),
            if (selectedRoute != null) ...[
              FadeInUp(
                delay: Duration(milliseconds: 400),
                child: Text("Select Bus",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 47, 168, 244),
                    )),
              ),
              SizedBox(height: 15),
              FadeInUp(
                delay: Duration(milliseconds: 500),
                child: DropdownButtonFormField<String>(
                  value: selectedBus,
                  hint: Text("Choose a Bus"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.indigo.shade50,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  items: busRoutes[selectedRoute!]!.map((bus) {
                    return DropdownMenuItem<String>(
                      value: bus,
                      child: Text(bus),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBus = value;
                    });
                  },
                ),
              ),
            ],
            Spacer(),
            FadeInUp(
              delay: Duration(milliseconds: 600),
              child: ElevatedButton(
                onPressed: selectedBus != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapScreen()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 47, 168, 244),
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                ),
                child: Text("Track Bus",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
