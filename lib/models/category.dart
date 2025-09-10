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

import 'package:flutter/material.dart';

enum SampleCategory {
  all('All', Icons.apps, 'assets/category_images/all_background.webp'),
  analysis(
    'Analysis',
    Icons.analytics,
    'assets/category_images/analysis_background.webp',
  ),
  cloudAndPortal(
    'Cloud and Portal',
    Icons.cloud,
    'assets/category_images/cloud_background.webp',
  ),
  editAndManageData(
    'Edit and Manage Data',
    Icons.edit,
    'assets/category_images/manage_data_background.webp',
  ),
  layers(
    'Layers',
    Icons.layers,
    'assets/category_images/layers_background.webp',
  ),
  maps(
    'Maps',
    Icons.map,
    'assets/category_images/maps_and_scenes_background.webp',
  ),
  routingAndLogistics(
    'Routing and Logistics',
    Icons.route,
    'assets/category_images/routing_and_logistics_background.webp',
  ),
  scenes(
    'Scenes',
    Icons.public,
    'assets/category_images/scenes_background.webp',
  ),
  searchAndQuery(
    'Search and Query',
    Icons.search,
    'assets/category_images/search_and_query_background.webp',
  ),
  utilityNetworks(
    'Utility Networks',
    Icons.polyline,
    'assets/category_images/utility_background.webp',
  ),
  visualization(
    'Visualization',
    Icons.visibility,
    'assets/category_images/visualization_background.webp',
  );

  const SampleCategory(this.title, this.icon, this.backgroundImage);
  final String title;
  final IconData icon;
  final String backgroundImage;
}
