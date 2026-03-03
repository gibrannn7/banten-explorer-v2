import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPreviewWidget extends StatefulWidget {
  final String keyword;

  const MapPreviewWidget({Key? key, required this.keyword}) : super(key: key);

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget> {
  late LatLng targetLocation;

  @override
  void initState() {
    super.initState();
    targetLocation = _getCoordinatesFromKeyword(widget.keyword);
  }

  LatLng _getCoordinatesFromKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    if (lowerKeyword.contains('tanjung lesung')) {
      return const LatLng(-6.4786, 105.6561);
    } else if (lowerKeyword.contains('carita') || lowerKeyword.contains('anyer')) {
      return const LatLng(-6.2994, 105.8400);
    } else if (lowerKeyword.contains('sawarna')) {
      return const LatLng(-6.9856, 106.3115);
    } else if (lowerKeyword.contains('merak')) {
      return const LatLng(-5.9324, 105.9965);
    }
    return const LatLng(-6.1200, 106.1502); 
  }

  Future<void> _openGoogleMaps() async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${targetLocation.latitude},${targetLocation.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: targetLocation,
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('target_location'),
                    position: targetLocation,
                    infoWindow: InfoWindow(title: widget.keyword),
                  ),
                },
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                scrollGesturesEnabled: false,
              ),
            ),
          ),
          GestureDetector(
            onTap: _openGoogleMaps,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Buka Rute di Google Maps',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
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