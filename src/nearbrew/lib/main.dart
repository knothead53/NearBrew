/*
  NearBrew — Step 1 (Location-only screen)
  -------------------------------------------------
  What this file does right now:
  • Requests location permission at runtime (Android).
  • Gets your current GPS coordinates once and shows them on screen.
  • Lots of comments so you can learn what each line is doing.

  Next steps (after you test this compiles & runs):
  • We will add the coffee search (OpenStreetMap/Overpass) and a list UI.
  • We will add a "Get Directions" action that opens Google Maps.
*/

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  // Entry point for the Flutter app. This runs once when the app starts.
  runApp(const NearBrewApp());
}

class NearBrewApp extends StatelessWidget {
  const NearBrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp sets up themes, navigation, and the root screen.
    return MaterialApp(
      title: 'NearBrew',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Material 3 look & a coffee-ish accent color.
        useMaterial3: true,
        colorSchemeSeed: Colors.brown,
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Holds the most recent location. It starts as null because we haven't fetched it yet.
  Position? _position;

  // For simple loading/error UI state.
  bool _loading = false;
  String? _error;

  // 1) Ask for permission (if needed). 2) If granted, read current GPS location.
  Future<void> _getLocationOnce() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ---- Step A: Is location service (GPS) turned on for the device? ----
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loading = false;
          _error = 'Location services are disabled. Please enable GPS.';
        });
        return; // Stop here because we cannot proceed without GPS.
      }

      // ---- Step B: Check permission status & request if denied. ----
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loading = false;
            _error = 'Location permission was denied.';
          });
          return; // User said no — nothing else to do here.
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // "Denied forever" means the user blocked it in system settings.
        setState(() {
          _loading = false;
          _error = 'Location permission is permanently denied.\n'
              'Open Settings > Apps > NearBrew > Permissions to enable.';
        });
        return;
      }

      // ---- Step C: All good — read the current position. ----
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _position = pos;
        _loading = false;
      });
    } catch (e) {
      // Any unexpected error ends up here.
      setState(() {
        _loading = false;
        _error = 'Failed to get location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NearBrew'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Step 1: Get your location',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the button below to request permission and read your current GPS coordinates.\n'
                      'Once this works, we\'ll add coffee search next.',
                    ),
                    const SizedBox(height: 16),

                    // Show a loading spinner while we ask for permission / get location.
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],

                    // Show an error message (if any).
                    if (_error != null && !_loading) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // Show coordinates if we have them.
                    if (_position != null && !_loading) ...[
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              const Text(
                                'Current Position',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text('Latitude:  ${_position!.latitude.toStringAsFixed(6)}'),
                              Text('Longitude: ${_position!.longitude.toStringAsFixed(6)}'),
                              if (_position!.timestamp != null) ...[
                                const SizedBox(height: 6),
                                Text('Timestamp: ${_position!.timestamp}'),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // The main button to trigger permission + location read.
                    FilledButton.icon(
                      onPressed: _loading ? null : _getLocationOnce,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my location'),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'Tip: The first time you tap this, Android will ask for permission.\n'
                      'If you deny permanently, you\'ll need to enable it in Settings later.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
