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
import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart'
    as arcgis_category;
import 'package:arcgis_maps_sdk_flutter_samples/widgets/about_info.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/category_card.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_viewer_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/theme_data.dart';
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
      home: SampleViewerApp(),
    ),
  );
}

class SampleViewerApp extends StatelessWidget {
  SampleViewerApp({super.key});

  final sampleViewerPage = SampleViewerPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: true,
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
                            top: Radius.circular(30.0),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20.0),
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
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: _buildCategoryRows(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryRows(BuildContext context) {
    List<Widget> rows = [];
    final cardHeight = MediaQuery.of(context).size.width / 2 - 20.0;

    for (int i = 0; i < arcgis_category.sampleCategories.length; i += 2) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: CategoryCard(
                  category: arcgis_category.sampleCategories[i],
                  onClick: () => _onCategoryClick(
                    context,
                    arcgis_category.sampleCategories[i],
                  ),
                ),
              ),
            ),
            if (i + 1 < arcgis_category.sampleCategories.length)
              Expanded(
                child: SizedBox(
                  height: cardHeight,
                  child: CategoryCard(
                    category: arcgis_category.sampleCategories[i + 1],
                    onClick: () => _onCategoryClick(
                      context,
                      arcgis_category.sampleCategories[i + 1],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return rows;
  }

  void _onCategoryClick(
    BuildContext context,
    arcgis_category.Category category,
  ) {
    sampleViewerPage.category = category;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => sampleViewerPage),
    );
  }
}
