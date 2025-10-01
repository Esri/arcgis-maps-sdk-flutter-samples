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
      GoRoute(
        path: '/',
        builder: (context, state) => const SampleViewerApp(),
        routes: [
          // Search route.
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

          // Category route.
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

          // Unified sample route: redirects to resources or live.
          GoRoute(
            path: 'sample/:sample',
            redirect: (context, state) {
              final sampleKey = state.pathParameters['sample']!;
              final sample = allSamples.firstWhere((s) => s.key == sampleKey);
              return sample.downloadableResources.isNotEmpty
                  ? '/sample/$sampleKey/resources'
                  : '/sample/$sampleKey/live';
            },
            routes: [
              // Downloadable resources page.
              GoRoute(
                path: 'resources',
                builder: (context, state) {
                  final sampleKey = state.pathParameters['sample']!;
                  final sample = allSamples.firstWhere(
                    (s) => s.key == sampleKey,
                  );
                  return DownloadableResourcesPage(
                    sampleTitle: sample.title,
                    resources: sample.downloadableResources,
                    onComplete: (_) {
                      context.go('/sample/$sampleKey/live');
                    },
                  );
                },
              ),

              // Live sample view.
              GoRoute(
                path: 'live',
                builder: (context, state) {
                  final sampleKey = state.pathParameters['sample']!;
                  final sample = allSamples.firstWhere(
                    (s) => s.key == sampleKey,
                  );
                  return SampleDetailPage(sample: sample);
                },
              ),

              // README page.
              GoRoute(
                path: 'README',
                builder: (context, state) {
                  final sampleKey = state.pathParameters['sample']!;
                  final sample = allSamples.firstWhere(
                    (s) => s.key == sampleKey,
                  );
                  return ReadmePage(sample: sample);
                },
              ),

              // Code view page.
              GoRoute(
                path: 'Code',
                builder: (context, state) {
                  final sampleKey = state.pathParameters['sample']!;
                  final sample = allSamples.firstWhere(
                    (s) => s.key == sampleKey,
                  );
                  return CodeViewPage(sample: sample);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// A minimal GoRouter for running a single sample in isolation,
/// starting at either its resources page or its live view.
GoRouter routerConfigWithSample(Sample sample, String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/sample/:sample/resources',
        builder: (context, state) {
          final key = state.pathParameters['sample']!;
          assert(
            key == sample.key,
            'Expected path parameter "sample" ($key) to match provided sample.key (${sample.key})',
          );
          return DownloadableResourcesPage(
            sampleTitle: sample.title,
            resources: sample.downloadableResources,
            onComplete: (_) {
              context.go('/sample/${sample.key}/live');
            },
          );
        },
      ),
      GoRoute(
        path: '/sample/:sample/live',
        builder: (context, state) {
          final key = state.pathParameters['sample']!;
          assert(
            key == sample.key,
            'Expected path parameter "sample" ($key) to match provided sample.key (${sample.key})',
          );
          return SampleDetailPage(sample: sample);
        },
      ),
    ],
  );
}
