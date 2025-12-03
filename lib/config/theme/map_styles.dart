/// Estilos personalizados para Google Maps con colores NETTALCO
class MapStyles {
  /// Estilo de mapa con colores corporativos NETTALCO
  /// Navy Primary: #1C224D
  /// Blue Secondary: #4A7AFF
  /// Mint Accent: #A2F0A1
  static const String nettalcoStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      { "color": "#f5f5f5" }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#ffffff" }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      { "color": "#e8f5e9" }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      { "color": "#c8e6c9" }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "color": "#ffffff" }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      { "color": "#e3e8ff" }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#4A7AFF" },
      { "lightness": 60 }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      { "color": "#4A7AFF" },
      { "lightness": 40 }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      { "color": "#A2F0A1" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      { "color": "#b3d4fc" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#1C224D" }
    ]
  }
]
''';

  /// Estilo de mapa nocturno con colores NETTALCO
  static const String nettalcoNightStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#A2F0A1" }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      { "color": "#4A7AFF" }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#4A7AFF" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      { "color": "#1C224D" }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      { "color": "#2A3066" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      { "color": "#141A3D" }
    ]
  }
]
''';

  /// Estilo minimalista para navegación
  static const String navigationStyle = '''
[
  {
    "featureType": "administrative",
    "elementType": "labels",
    "stylers": [
      { "visibility": "simplified" }
    ]
  },
  {
    "featureType": "poi",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.park",
    "stylers": [
      { "visibility": "on" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      { "color": "#e8eaff" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      { "color": "#c5d4ff" }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      { "color": "#4A7AFF" },
      { "weight": 1 }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry",
    "stylers": [
      { "color": "#ffffff" }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      { "color": "#b8d4f0" }
    ]
  }
]
''';
}

