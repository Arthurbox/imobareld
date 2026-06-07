import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;

  // Coordonnées initiales — Ouagadougou (Burkina Faso)
  late LatLng _currentCenter;
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation ?? const LatLng(12.3714, -1.5197);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le service de localisation est désactivé.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les permissions de localisation sont refusées.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les permissions sont définitivement refusées.')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    mapController.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentCenter = position.target;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: const Text(
          'Sélectionner l\'emplacement',
          style: TextStyle(
            color: Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Retourner les coordonnées choisies à la page précédente
              Navigator.pop(context, _currentCenter);
            },
            icon: const Icon(Icons.check, color: Color(0xFF0D47A1)),
            label: const Text(
              'Confirmer',
              style: TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. La carte Google Maps
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 16.0,
            ),
            onCameraMove: _onCameraMove,
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. Le marqueur central fixe au centre de l'écran
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: Icon(
                Icons.location_on,
                size: 50.0,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),

          // 3. Bulle d'information en haut
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Faites glisser la carte pour positionner le centre exactement',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Boutons flottants (Position actuelle et Satellite)
          Positioned(
            bottom: 120.0,
            right: 16.0,
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _goToMyLocation,
                    icon: const Icon(Icons.my_location, color: Color(0xFF0D47A1)),
                    tooltip: 'Ma position',
                  ),
                  Container(
                    height: 1,
                    width: 30,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _currentMapType = _currentMapType == MapType.normal
                            ? MapType.satellite
                            : MapType.normal;
                      });
                    },
                    icon: Icon(
                      _currentMapType == MapType.normal
                          ? Icons.satellite_alt_outlined
                          : Icons.map_outlined,
                      color: const Color(0xFF0D47A1),
                    ),
                    tooltip: 'Changer la carte',
                  ),
                ],
              ),
            ),
          ),

          // 5. Panneau des coordonnées en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'COORDONNÉES PRÉCISES',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${_currentCenter.latitude.toStringAsFixed(6)}, ${_currentCenter.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
