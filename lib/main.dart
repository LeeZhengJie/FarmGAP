import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// import 'package:farm_gap/maps.dart';
import 'package:farm_gap/mapbox_gl.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const List<FillLayer> fillLayers = [
    FillLayer(geometry: [
      [
        LatLng(6.523777171253258, 100.23325296879375),
        LatLng(6.522984562275369, 100.23319938961401),
        LatLng(6.522847106075915, 100.23493311170915),
        LatLng(6.52380337084189, 100.23494532813106),
        LatLng(6.523777171253258, 100.23325296879375),
      ]
    ], fillColor: "red"),
    FillLayer(geometry: [
      [
        LatLng(6.523772006950509, 100.23326217656165),
        LatLng(6.5229885042338225, 100.23320233137463),
        LatLng(6.522961213163711, 100.23359724691113),
        LatLng(6.5237764013534445, 100.23365461738877),
        LatLng(6.523772006950509, 100.23326217656165),
      ]
    ], fillColor: "#00d5c8"),
    FillLayer(geometry: [
      [
        LatLng(6.523777137991814, 100.2336673875322),
        LatLng(6.52296038991507, 100.23361206212189),
        LatLng(6.522960387648396, 100.23360984248461),
        LatLng(6.522934950454001, 100.23392636141904),
        LatLng(6.523782092334898, 100.23398380033484),
      ]
    ], fillColor: "#ffffff"),
    FillLayer(geometry: [
      [
        LatLng(6.523782680510081, 100.23399098012288),
        LatLng(6.522934692138051, 100.23393993477487),
        LatLng(6.522908127310927, 100.23425353265054),
        LatLng(6.523787137153192, 100.23431095408932),
        LatLng(6.523782680510081, 100.23399098012288),
      ]
    ], fillColor: "yellow"),
    FillLayer(geometry: [
      [
        LatLng(6.523788436534602, 100.23432691704477),
        LatLng(6.522908326992436, 100.23427088964479),
        LatLng(6.522855929560549, 100.23492416873881),
        LatLng(6.523795116829817, 100.23493400043532),
        LatLng(6.523788436534602, 100.23432691704477),
      ]
    ], fillColor: "pink"),
  ];

  static const _cemeraPosition = CameraPosition(
    target: LatLng(6.523376191864045, 100.23408947709027),
    zoom: 18.454236564204464 - 0.5,
    bearing: 93,
    tilt: 0,
  );

  List<Map<dynamic, dynamic>>? markers;

  void _getMarkers() async {
    final response = await http
        .get(Uri.parse("https://app.farmgap.my:8000/asset_locations"));
    final body = json.decode(response.body);
    markers = List<Map<dynamic, dynamic>>.from(body);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (markers == null) {
      _getMarkers();
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }

    var mapboxGL = MapBoxGL(
      initialCameraPosition: _cemeraPosition,
      polygons: fillLayers
          .map<FillOptions>((fillLayer) => FillOptions(
              fillColor: fillLayer.fillColor,
              geometry: fillLayer.geometry,
              fillOpacity: 0.5))
          .toList(),
      markers: MarkerLists(
        iconImage: "assets/tree_icon_32.png",
        markersData: markers!,
        scalePreference: const ScalePreference(17.65, 22, 0.3, 12.0),
        idleBackgroundColor: "green",
        pendingBackgroundColor: "red",
      ),
    );

    final selectedMaps = mapboxGL;

    action() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => selectedMaps,
          ),
        );

    return Scaffold(
      body: Center(
        child: ElevatedButton(onPressed: action, child: const Text('To Maps')),
      ),
    );
  }
}

class FillLayer {
  final List<List<LatLng>> geometry;
  final String fillColor;

  const FillLayer({
    required this.geometry,
    required this.fillColor,
  });
}
