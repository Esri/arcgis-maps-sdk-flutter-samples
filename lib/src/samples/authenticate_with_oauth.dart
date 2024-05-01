import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'authenticate_with_oauth_sample.dart';

void main() {
  const apiKey = String.fromEnvironment('API_KEY');
  if (apiKey.isEmpty) {
    throw Exception('apiKey undefined');
  } else {
    ArcGISEnvironment.apiKey = apiKey;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AuthenticateWithOAuthSample(title: 'Authenticate with OAuth'),
    );
  }
}
