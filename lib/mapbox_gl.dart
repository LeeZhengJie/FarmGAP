import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'env/env.dart';
import 'dart:math';

export 'package:mapbox_gl/mapbox_gl.dart';

class MapBoxGL extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final List<FillOptions> polygons;
  final MarkerLists markers;

  const MapBoxGL({
    super.key,
    required this.initialCameraPosition,
    required this.polygons,
    required this.markers,
  });

  @override
  State<MapBoxGL> createState() => _MapBoxGLState();
}

class _MapBoxGLState extends State<MapBoxGL> {
  late MapboxMapController _mapController;
  bool _onInterval = false, _initialized = false;

  void _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapController.onFeatureTapped.add(onFeatureTap);
  }

  void _onStyleLoadedCallBack() async {
    await _addPolygons();
    await _addMarkers();
    _mapController.addListener(_onCameraMoving);
    _initialized = true;
  }

  Future<void> _addPolygons() async {
    await _mapController.addFills(widget.polygons);
  }

  Future<void> _addMarkers() async {
    final ByteData bytes = await rootBundle.load(widget.markers.iconImage);
    final Uint8List markerImage = bytes.buffer.asUint8List();
    await _mapController.addImage("markerImage", markerImage);

    await _mapController.addGeoJsonSource("markers", _markers());

    await _mapController.addCircleLayer(
      "markers",
      "idleTaskCircles",
      CircleLayerProperties(
        circleRadius: ["get", "circleRadius"],
        circleColor: widget.markers.idleBackgroundColor,
      ),
      filter: [
        "==",
        ["get", "status"],
        "completed"
      ],
    );

    await _mapController.addCircleLayer(
      "markers",
      "pendingTaskCircles",
      CircleLayerProperties(
        circleRadius: ["get", "circleRadius"],
        circleColor: widget.markers.pendingBackgroundColor,
      ),
      filter: [
        "==",
        ["get", "status"],
        "pending"
      ],
    );

    await _mapController.addSymbolLayer(
      "markers",
      "symbols",
      const SymbolLayerProperties(
        iconImage: "markerImage",
        iconSize: ["get", "iconSize"],
        textField: ["get", "textField"],
        textSize: ["get", "textSize"],
        textOffset: [0, 0.9], // Not working
        iconAllowOverlap: true,
        textAllowOverlap: true,
      ),
    );
  }

  void _onCameraIdle() {
    if (_initialized) {
      _mapController.setGeoJsonSource("markers", _markers());
    }
  }

  void _onCameraMoving() async {
    if (_mapController.isCameraMoving && !_onInterval) {
      _onInterval = true;
      _mapController.setGeoJsonSource("markers", _markers());
      await Future.delayed(const Duration(milliseconds: 200));
      _onInterval = false;
    }
  }

  Map<String, dynamic> _markers() {
    final markerSize = _calculateMarkerSize();
    final textSize = markerSize * 5;
    final circleRadius = markerSize * 6;

    final features = widget.markers.markersData
        .asMap()
        .entries
        .map((marker) => {
              "type": "Feature",
              "id": "symbol-${marker.key}",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  marker.value["longitude"],
                  marker.value["latitude"],
                ],
              },
              "properties": {
                "iconImage": widget.markers.iconImage,
                "iconSize": markerSize,
                "textField": marker.value["asset_label"],
                "textSize": textSize,
                "circleRadius": circleRadius,
                "status":
                    marker.value["tasks"].every((task) => task == "completed")
                        ? "completed"
                        : "pending",
              },
            })
        .toList();

    final markers = {
      "type": "FeatureCollection",
      "features": features,
    };

    return markers;
  }

  dynamic _calculateMarkerSize() {
    final scalePrefs = widget.markers.scalePreference;
    double cameraZoom = _mapController.cameraPosition!.zoom;

    if (cameraZoom < scalePrefs.minZoom) {
      return scalePrefs.minSize;
    } else if (cameraZoom > scalePrefs.maxZoom) {
      return scalePrefs.maxSize;
    }

    // get value by parabola graph y = ax^2 + c
    // more refrences for the "increasing graph", browser "y = x^2"
    final scaleData = widget.markers.scaleData;
    final scale = (scaleData["a"] * pow(cameraZoom, 2)) - scaleData["c"];

    return scale;
  }

  void onFeatureTap(dynamic featureId, Point<double> point, LatLng latLng) {
    print("featureID: $featureId, point: $point, latlng: $latLng");
    if (featureId.toString().startsWith("symbol")) {
      // TODO: selected marker
      print("$featureId is selected");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _mapController.removeListener(_onCameraMoving);
  }

  @override
  Widget build(BuildContext context) {
    MapboxMap mapboxMap = MapboxMap(
      accessToken: Env.mapboxAccessToken,
      onMapCreated: _onMapCreated,
      onCameraIdle: _onCameraIdle,
      onStyleLoadedCallback: _onStyleLoadedCallBack,
      initialCameraPosition: widget.initialCameraPosition,
      styleString: 'mapbox://styles/mapbox/satellite-v9',
      logoViewMargins: const Point<num>(-100, -100),
      attributionButtonMargins: const Point<num>(-100, -100),
      trackCameraPosition: true,
      annotationOrder: const [
        AnnotationType.fill,
        AnnotationType.line,
        AnnotationType.circle,
        AnnotationType.symbol,
      ],
      annotationConsumeTapEvents: const [AnnotationType.symbol],
      minMaxZoomPreference: const MinMaxZoomPreference(17.95, null),
    );

    return mapboxMap;
  }
}

class MarkerLists {
  final String iconImage;
  final List<Map<dynamic, dynamic>> markersData;
  final ScalePreference scalePreference;
  final String idleBackgroundColor, pendingBackgroundColor;
  late final Map<dynamic, dynamic> scaleData;

  MarkerLists({
    required this.iconImage,
    required this.markersData,
    required this.scalePreference,
    required this.idleBackgroundColor,
    required this.pendingBackgroundColor,
  }) {
    // formula for graph y = ax^2 + c, calculation for marker scaling
    final a = (-scalePreference.minSize + scalePreference.maxSize) /
        (pow(scalePreference.maxZoom, 2) - pow(scalePreference.minZoom, 2));
    final c = (a * pow(scalePreference.minZoom, 2)) - scalePreference.minSize;

    scaleData = {"a": a, "c": c};
  }
}

class ScalePreference {
  final double minZoom, maxZoom;
  final double minSize, maxSize;

  const ScalePreference(this.minZoom, this.maxZoom, this.minSize, this.maxSize);
}

// IGNORE: offline region - incomplete
class OfflineRegionListItem {
  OfflineRegionListItem({
    required this.offlineRegionDefinition,
    required this.downloadedId,
    required this.isDownloading,
    required this.name,
    required this.initialCameraPosition,
    required this.polygons,
    required this.markers,
  });

  final OfflineRegionDefinition offlineRegionDefinition;
  final int? downloadedId;
  final bool isDownloading;
  final String name;
  final CameraPosition initialCameraPosition;
  final List<FillOptions> polygons;
  final MarkerLists markers;

  OfflineRegionListItem copyWith({
    int? downloadedId,
    bool? isDownloading,
  }) =>
      OfflineRegionListItem(
        offlineRegionDefinition: offlineRegionDefinition,
        name: name,
        downloadedId: downloadedId,
        isDownloading: isDownloading ?? this.isDownloading,
        initialCameraPosition: initialCameraPosition,
        polygons: polygons,
        markers: markers,
      );

  bool get isDownloaded => downloadedId != null;
}
