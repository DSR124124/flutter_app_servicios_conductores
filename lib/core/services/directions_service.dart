import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

/// Servicio para obtener rutas de navegación usando Google Directions API
class DirectionsService {
  // API Key de Google Maps (debe tener Directions API habilitada)
  static const String _apiKey = 'AIzaSyCnJC_qbY41ZsXjgDLhTmcSK6GkkcL-_pw';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Obtiene la ruta de navegación óptima entre múltiples paraderos
  /// Usa una sola llamada a Directions API con waypoints
  static Future<List<LatLng>> getRouteCoordinates(List<LatLng> paraderos) async {
    if (paraderos.length < 2) return [];

    final origin = paraderos.first;
    final destination = paraderos.last;
    final waypoints = paraderos.length > 2 
        ? paraderos.sublist(1, paraderos.length - 1) 
        : <LatLng>[];

    try {
      // Construir URL con waypoints
      String url = '$_baseUrl'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$_apiKey';

      // Agregar waypoints intermedios si existen
      if (waypoints.isNotEmpty) {
        final waypointsParam = waypoints
            .map((w) => '${w.latitude},${w.longitude}')
            .join('|');
        url += '&waypoints=$waypointsParam';
      }

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        if (status == 'OK' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final encodedPolyline = route['overview_polyline']['points'];
          final points = _decodePolyline(encodedPolyline);
          return points;
        }
      }
    } catch (_) {
      // Silenciar errores
    }

    return [];
  }

  /// Decodifica el polyline encoded de Google
  static List<LatLng> _decodePolyline(String encoded) {
    final polylinePoints = PolylinePoints();
    final decodedPoints = polylinePoints.decodePolyline(encoded);
    
    return decodedPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }
}
