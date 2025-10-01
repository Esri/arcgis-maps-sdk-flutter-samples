//
// Copyright 2025 Esri
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

import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/sample_viewer_app.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/category_transition_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/code_view_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/downloadable_resources_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/readme_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/ripple_transition_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_detail_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

GoRouter routerConfig(List<Sample> allSamples) {
  return GoRouter(
    routes: [
      // Main route to SampleViewerApp.
      GoRoute(
        path: '/',
        builder: (context, state) => const SampleViewerApp(),
        routes: [
          // Route to the SampleViewerPage in "search" mode.
          GoRoute(
            path: 'search',
            pageBuilder: (context, state) {
              final position = state.extra as Offset? ?? Offset.zero;

              return RippleTransitionPage(
                position: position,
                child: SampleViewerPage(allSamples: allSamples),
              );
            },
          ),
          // Route to the SampleViewerPage with the given category.
          GoRoute(
            path: 'category/:category',
            pageBuilder: (context, state) {
              final categoryName = state.pathParameters['category'];
              final category = SampleCategory.values.firstWhere(
                (c) => c.name == categoryName,
                orElse: () => SampleCategory.all,
              );
              return CategoryTransitionPage(
                child: SampleViewerPage(
                  allSamples: allSamples,
                  category: category,
                ),
              );
            },
          ),
          // Route to the given sample running live.
          GoRoute(
            path: 'sample/:sample/live',
            builder: (context, state) {
              final sampleKey = state.pathParameters['sample'];
              final sample = allSamples
                  .where((sample) => sample.key == sampleKey)
                  .first;

              return SampleDetailPage(sample: sample);
            },
          ),
          // Route to downloadable resources page for a sample.
          GoRoute(
            path: 'sample/:sample/resources',
            builder: (context, state) {
              final sampleKey = state.pathParameters['sample'];
              final sample = allSamples
                  .where((sample) => sample.key == sampleKey)
                  .first;

              return DownloadableResourcesPage(
                sampleTitle: sample.title,
                resources: sample.downloadableResources,
                onComplete: (downloadPaths) {
                  context.go('/sample/${sample.key}/live', extra: downloadPaths);
                },
              );
            },
          ),
          // Route to the README page for the given sample.
          GoRoute(
            path: 'sample/:sample/README',
            builder: (context, state) {
              final sampleKey = state.pathParameters['sample'];
              final sample = allSamples
                  .where((sample) => sample.key == sampleKey)
                  .first;

              return ReadmePage(sample: sample);
            },
          ),
          // Route to the Code page for the given sample.
          GoRoute(
            path: 'sample/:sample/Code',
            builder: (context, state) {
              final sampleKey = state.pathParameters['sample'];
              final sample = allSamples
                  .where((sample) => sample.key == sampleKey)
                  .first;

              return CodeViewPage(sample: sample);
            },
          ),
        ],
      ),
    ],
  );
}

GoRouter routerConfigWithSample(Sample sample, String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/:sample/resources',
        builder: (context, state) {
          return DownloadableResourcesPage(
            sampleTitle: sample.title,
            resources: sample.downloadableResources,
            onComplete: (downloadPaths) {
              context.go('/${sample.key}/live', extra: downloadPaths);
            },
          );
        },
      ),
      GoRoute(
        path: '/:sample/live',
        builder: (context, state) {
          return sample.getSampleWidget();
        },
      ),
    ],
  );
}
