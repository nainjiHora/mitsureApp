import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AgentsMapScreen extends StatefulWidget {
  // List of agents with lat/lng and metadata



  @override
  State<AgentsMapScreen> createState() => _AgentsMapScreenState();
}

class _AgentsMapScreenState extends State<AgentsMapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  List<Map<String, dynamic>> agents = [
  {"id": 1, "name": "John", "phone": "1234567890", "lat": 28.7041, "lng": 77.1025},
  {"id": 2, "name": "Sara", "phone": "9876543210", "lat": 28.5355, "lng": 77.3910},
];


  @override
  void initState() {
    super.initState();
    _initMarkers();
  }

  void _initMarkers() {
    for (var agent in agents) {
      final marker = Marker(
        markerId: MarkerId(agent['id'].toString()),
        position: LatLng(agent['lat'], agent['lng']),
        infoWindow: InfoWindow(
          title: agent['name'],
          snippet: 'Phone: ${agent['phone']}',
        ),
      );
      _markers.add(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agent Locations")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(agents[0]['lat'], agents[0]['lng']),
          zoom: 10,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
