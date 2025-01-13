//
// Copyright 2024 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/theme_data.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/about_info.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/category_card.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_viewer_page.dart';
import 'package:flutter/material.dart';

void main() {
  // Supply your apiKey using the --dart-define-from-file command line argument.
  const apiKey = String.fromEnvironment('API_KEY');
  // Alternatively, replace the above line with the following and hard-code your apiKey here:
  // const apiKey = ''; // Your API Key here.
  if (apiKey.isEmpty) {
    throw Exception('apiKey undefined');
  } else {
    ArcGISEnvironment.apiKey = apiKey;
  }

  runApp(
    MaterialApp(
      theme: sampleViewerTheme,
      home: const SampleViewerApp(),
    ),
  );
}

class SampleViewerApp extends StatefulWidget {
  const SampleViewerApp({super.key});

  @override
  State<SampleViewerApp> createState() => _SampleViewerAppState();
}

class _SampleViewerAppState extends State<SampleViewerApp> {
  static const double cardSpacing = 6;

  @override
  Widget build(BuildContext context) {
    const applicationTitle = 'ArcGIS Maps SDK for Flutter Samples';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) {
                return FractionallySizedBox(
                  heightFactor: 0.5,
                  child: Column(
                    children: [
                      AppBar(
                        automaticallyImplyLeading: false,
                        title: const Text('About'),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: const AboutInfo(title: applicationTitle),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(cardSpacing, cardSpacing, 0, 0),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return SingleChildScrollView(
              child: Wrap(
                spacing: cardSpacing,
                runSpacing: cardSpacing,
                children: _buildCategoryCards(context, orientation),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SampleViewerPage()),
          );
        },
        child: const Icon(Icons.search),
      ),
    );
  }

  List<Widget> _buildCategoryCards(BuildContext context, Orientation orientation) {
    var cardSize = MediaQuery.of(context).size.width / 2 - cardSpacing * 2;
    if (orientation == Orientation.landscape) {
      cardSize = MediaQuery.of(context).size.height / 2 - cardSpacing * 2;
    }
    return List<Widget>.generate(
      SampleCategory.values.length,
      (i) => SizedBox(
        height: cardSize,
        width: cardSize,
        child: CategoryCard(
          category: SampleCategory.values[i],
          onClick: () => _onCategoryClick(
            context,
            SampleCategory.values[i],
          ),
        ),
      ),
    );
  }

  void _onCategoryClick(
    BuildContext context,
    SampleCategory category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SampleViewerPage(category: category)),
    );
  }
}
