import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/problem_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(24.8607, 67.0011); // Karachi as default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemProvider>(context, listen: false).fetchProblems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Issues Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter dialog
            },
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: problemProvider.problems.map((p) => Marker(
          markerId: MarkerId(p.problemId),
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(title: p.title, snippet: p.status.name),
          onTap: () {
            // Show bottom sheet with details
          },
        )).toSet(),
      ),
    );
  }
}
