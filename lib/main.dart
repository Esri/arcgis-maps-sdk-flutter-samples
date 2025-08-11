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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

void main() {
  // Supply your apiKey using the --dart-define-from-file command line argument.
  const apiKey = String.fromEnvironment('API_KEY');
  // Alternatively, replace the above line with the following and hard-code your apiKey here:
  // const apiKey = ''; // Your API Key here.
  ArcGISEnvironment.apiKey = apiKey;

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SampleViewerApp(),
        routes: [
          GoRoute(
            path: 'category/:category',
            pageBuilder: (context, state) {
              final categoryName = state.pathParameters['category'];
              final category = SampleCategory.values.firstWhere(
                (c) => c.name == categoryName,
                orElse: () => SampleCategory.all,
              );
              return CategoryTransitionPage(
                child: SampleViewerPage(category: category),
              );
            },
          ),
          GoRoute(
            path: 'search',
            pageBuilder: (context, state) =>
                CategoryTransitionPage(child: const SampleViewerPage()),
          ),
        ],
      ),
    ],
  );

  runApp(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        return locale;
      },
      theme: sampleViewerTheme,
    ),
  );
}

class SampleViewerApp extends StatefulWidget {
  const SampleViewerApp({super.key});

  @override
  State<SampleViewerApp> createState() => _SampleViewerAppState();
}

class _SampleViewerAppState extends State<SampleViewerApp>
    with SingleTickerProviderStateMixin {
  static const double cardSpacing = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showModalBottomSheet<void>(
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
        padding: const EdgeInsets.all(cardSpacing),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return SingleChildScrollView(
              child: _ResponsiveCategoryGrid(orientation: orientation),
            );
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () => context.go('/search'),
            child: const Icon(Icons.search),
          );
        },
      ),
    );
  }
}

class _ResponsiveCategoryGrid extends StatelessWidget {
  const _ResponsiveCategoryGrid({required this.orientation});
  final Orientation orientation;
  static const double cardSpacing = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var cardSize = (constraints.maxWidth - cardSpacing) / 2;
        if (orientation == Orientation.landscape) {
          cardSize = (constraints.maxHeight - cardSpacing) / 2;
        }
        return Wrap(
          spacing: cardSpacing,
          runSpacing: cardSpacing,
          children: List.generate(
            SampleCategory.values.length,
            (i) => SizedBox(
              height: cardSize,
              width: cardSize,
              child: CategoryCard(
                category: SampleCategory.values[i],
                onClick: () =>
                    context.go('/category/${SampleCategory.values[i].name}'),
                index: i,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Custom transition page for category navigation (scale + fade + curve).
class CategoryTransitionPage extends CustomTransitionPage<void> {
  CategoryTransitionPage({required super.child})
    : super(
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1).animate(curved),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}
