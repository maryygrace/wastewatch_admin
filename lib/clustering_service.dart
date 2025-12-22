import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:latlong2/latlong.dart';
import 'package:wastewatch_admin/services/supabase_service.dart';

/// IMPORTANT: You must configure API keys for Google Maps Platform for this to work.
/// See: https://pub.dev/packages/google_maps_flutter

/// --- 1. Data Models ---

/// Model matching the output of your Python API / Supabase predictions table.
class ClusterPrediction {
  final double latitude;
  final double longitude;
  final int clusterLabel; // -1: Noise/Outlier, >= 0: Defined Cluster

  ClusterPrediction({
    required this.latitude,
    required this.longitude,
    required this.clusterLabel,
  });

  factory ClusterPrediction.fromJson(Map<String, dynamic> json) {
    return ClusterPrediction(
      // Ensure data types are handled correctly from JSON (which may return int for lat/lng)
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      clusterLabel: json['cluster_label'] as int,
    );
  }
}

/// Model for the final map markers (either a cluster centroid or a single outlier).
class MapMarkerData {
  final String id;
  final double lat;
  final double lng;
  final int count;
  final bool isCluster;
  final int clusterLabel;

  MapMarkerData({
    required this.id,
    required this.lat,
    required this.lng,
    required this.count,
    required this.isCluster,
    required this.clusterLabel,
  });
}

/// --- 2. Client-Side Processing Logic ---

class ClusterDisplayService {
  /// Processes raw DBSCAN predictions to calculate cluster centroids and
  /// prepares data for map display markers.
  List<MapMarkerData> processPredictions(List<ClusterPrediction> predictions) {
    // Group points by cluster label
    final Map<int, List<ClusterPrediction>> clusters = {};
    for (var p in predictions) {
      clusters.putIfAbsent(p.clusterLabel, () => []).add(p);
    }

    final List<MapMarkerData> markers = [];
    
    clusters.forEach((label, points) {
      if (label == -1) {
        // --- Outliers/Noise (-1) ---
        // Each noise point is displayed as a single marker
        for (var i = 0; i < points.length; i++) {
          final p = points[i];
          markers.add(MapMarkerData(
            id: 'noise_$i',
            lat: p.latitude,
            lng: p.longitude,
            count: 1,
            isCluster: false,
            clusterLabel: -1,
          ));
        }
      } else {
        // --- Proper Cluster (label >= 0) ---
        
        // 1. Calculate the Centroid (Central Point)
        // For simple map display, the average of all points in the cluster works as the centroid.
        double sumLat = 0;
        double sumLng = 0;
        for (var p in points) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        
        final double centroidLat = sumLat / points.length;
        final double centroidLng = sumLng / points.length;
        
        // 2. Create the Cluster Marker (Centroid)
        markers.add(MapMarkerData(
          id: 'cluster_$label',
          lat: centroidLat,
          lng: centroidLng,
          count: points.length,
          isCluster: true,
          clusterLabel: label,
        ));
      }
    });

    return markers;
  }
}


/// --- 3. Flutter App UI Implementation ---

class ClusterMapScreen extends StatefulWidget {
  const ClusterMapScreen({super.key});

  @override
  State<ClusterMapScreen> createState() => _ClusterMapScreenState();
}

class _ClusterMapScreenState extends State<ClusterMapScreen> {
  List<MapMarkerData> _markers = [];
  bool _isLoading = true;
  String? _error;
  final ClusterDisplayService _service = ClusterDisplayService();
  final SupabaseService _supabaseService = SupabaseService();
  final _log = Logger('ClusterMapScreen');

  @override
  void initState() {
    super.initState();
    _fetchAndProcessData();
  }

  Future<void> _fetchAndProcessData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch real data from Supabase.
      final List<Map<String, dynamic>> rawData = await _supabaseService.fetchPredictions();

      // Convert the raw map data into a list of ClusterPrediction objects.
      final rawPredictions = rawData.map((json) => ClusterPrediction.fromJson(json)).toList();
      
      // 2. Process data to calculate Centroids (Central Points)
      final processedMarkers = _service.processPredictions(rawPredictions);

      setState(() {
        _markers = processedMarkers;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Failed to load or process clustering data: $e';
        _isLoading = false;
      });
      _log.severe('Failed to load or process clustering data', e);
    }
  }

  /// Converts a lat/lng to a human-readable address.
  /// This now uses the open-source Nominatim service.
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng');
      // Nominatim requires a User-Agent header.
      final response = await http
          .get(url, headers: {'User-Agent': 'WasteWatchAdmin/1.0'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['display_name'] ?? 'Address not found';
      } else {
        _log.warning('Nominatim request failed with status: ${response.statusCode}');
        return 'Failed to fetch address';
      }
    } catch (e) {
      _log.warning('Could not find address for ($lat, $lng)', e);
      return "Address not found";
    }
  }

  /// Shows a bottom sheet with details about the tapped cluster.
  void _onMarkerTapped(MapMarkerData markerData) async {
    // Only fetch address for actual clusters
    String address = 'N/A (Outlier)';
    if (markerData.isCluster) {
      address = await _getAddressFromLatLng(markerData.lat, markerData.lng);
    }
    if (!mounted) return;
    _showClusterDetails(markerData, address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Cluster Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAndProcessData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('Error: $_error', style: const TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                )
              : FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(10.5667, 122.6167), // Center on Guimaras
                    initialZoom: 11.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wastewatch_admin',
                    ),
                    MarkerLayer(
                      markers: _markers.map((markerData) {
                        return Marker(
                          point: LatLng(markerData.lat, markerData.lng),
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () => _onMarkerTapped(markerData),
                            child: Tooltip(
                              message: markerData.isCluster
                                  ? 'Cluster ${markerData.clusterLabel} (${markerData.count} reports)'
                                  : 'Outlier',
                              child: Icon(
                                Icons.location_pin,
                                color: markerData.isCluster ? Colors.blue : Colors.red,
                                size: 40,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
      bottomNavigationBar: _buildSummaryBar(),
    );
  }

  Widget _buildSummaryBar() {
    final int clusterCount = _markers.where((m) => m.isCluster).length;
    final int noiseCount = _markers.where((m) => m.clusterLabel == -1).length;
    final int totalPoints = _markers.fold(0, (sum, m) => sum + m.count);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.black12,
        border: Border(top: BorderSide(color: Colors.black26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Points', totalPoints.toString(), Colors.indigo),
          _buildSummaryItem('Clusters Found', clusterCount.toString(), Colors.green.shade700),
          _buildSummaryItem('Outliers/Noise', noiseCount.toString(), Colors.red.shade700),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  void _showClusterDetails(MapMarkerData marker, String address) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(marker.isCluster ? 'Cluster ${marker.clusterLabel} Details' : 'Outlier Details'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  _buildDetailRow(Icons.pin_drop, 'Centroid Location', '${marker.lat.toStringAsFixed(5)}, ${marker.lng.toStringAsFixed(5)}'),
                  if (marker.isCluster)
                    _buildDetailRow(Icons.location_city, 'Approximate Address', address),
                  _buildDetailRow(Icons.summarize, 'Total Reports', marker.count.toString()),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
