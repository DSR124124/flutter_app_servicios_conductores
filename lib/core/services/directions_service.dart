import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

/// Instrucción de navegación turn-by-turn
class NavigationInstruction {
  final String instruction;
  final String? maneuver; // 'turn-left', 'turn-right', 'straight', etc.
  final double distance; // en metros
  final int duration; // en segundos
  final LatLng? location;

  NavigationInstruction({
    required this.instruction,
    this.maneuver,
    required this.distance,
    required this.duration,
    this.location,
  });
}

/// Respuesta completa de navegación
class NavigationResponse {
  final List<LatLng> route;
  final List<NavigationInstruction> instructions;
  final int totalDistance; // en metros
  final int totalDuration; // en segundos

  NavigationResponse({
    required this.route,
    required this.instructions,
    required this.totalDistance,
    required this.totalDuration,
  });
}

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

  /// Obtiene la ruta completa con instrucciones turn-by-turn
  static Future<NavigationResponse?> getNavigationRoute(List<LatLng> paraderos) async {
    if (paraderos.length < 2) return null;

    final origin = paraderos.first;
    final destination = paraderos.last;
    final waypoints = paraderos.length > 2 
        ? paraderos.sublist(1, paraderos.length - 1) 
        : <LatLng>[];

    try {
      String url = '$_baseUrl'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&language=es'
          '&key=$_apiKey';

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
          final leg = route['legs'][0];
          
          // Decodificar polyline
          final encodedPolyline = route['overview_polyline']['points'];
          final routePoints = _decodePolyline(encodedPolyline);
          
          // Extraer instrucciones
          final instructions = <NavigationInstruction>[];
          final steps = leg['steps'] as List;
          
          for (final step in steps) {
            final distance = (step['distance']['value'] as num).toDouble();
            final duration = step['duration']['value'] as int;
            final htmlInstruction = step['html_instructions'] as String;
            final maneuver = step['maneuver'] as String?;
            
            // Extraer coordenadas del step
            final stepPolyline = step['polyline']['points'] as String;
            final stepPoints = _decodePolyline(stepPolyline);
            final location = stepPoints.isNotEmpty ? stepPoints.first : null;
            
            // Limpiar HTML de la instrucción
            final cleanInstruction = htmlInstruction
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .trim();
            
            instructions.add(NavigationInstruction(
              instruction: cleanInstruction,
              maneuver: maneuver,
              distance: distance,
              duration: duration,
              location: location,
            ));
          }
          
          final totalDistance = (leg['distance']['value'] as num).toInt();
          final totalDuration = (leg['duration']['value'] as num).toInt();
          
          return NavigationResponse(
            route: routePoints,
            instructions: instructions,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
          );
        }
      }
    } catch (_) {
      // Silenciar errores
    }

    return null;
  }

  /// Calcula la distancia desde un punto hasta la ruta más cercana
  static double distanceToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;
    
    double minDistance = double.infinity;
    for (final routePoint in route) {
      final distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
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
