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

class Category {
  Category({
    required this.title,
    required this.icon,
    required this.backgroundImage,
  });

  final String title;
  final IconData icon;
  final String backgroundImage;
}

enum SampleCategory {
  all('All'),
  analysis('Analysis'),
  // augmentedReality('Augmented Reality'),
  cloudAndPortal('Cloud and Portal'),
  editAndManageData('Edit and Manage Data'),
  layers('Layers'),
  maps('Maps'),
  routingAndLogistics('Routing and Logistics'),
  // scenes('Scenes'),
  searchAndQuery('Search and Query'),
  // utilityNetworks('Utility Networks'),
  visualization('Visualization');
  // favorites('Favorites');

  const SampleCategory(this.title);
  final String title;
}

final List<Category> sampleCategories = [
  Category(
    title: SampleCategory.all.title,
    icon: Icons.apps,
    backgroundImage: 'assets/category_images/all_background.webp',
  ),
  Category(
    title: SampleCategory.analysis.title,
    icon: Icons.analytics,
    backgroundImage: 'assets/category_images/analysis_background.webp',
  ),
  // Category(
  //   title: SampleCategory.augmentedReality.title,
  //   icon: Icons.view_in_ar,
  //   backgroundImage: 'assets/category_images/augmented_reality_background.webp',
  // ),
  Category(
    title: SampleCategory.cloudAndPortal.title,
    icon: Icons.cloud,
    backgroundImage: 'assets/category_images/cloud_background.webp',
  ),
  Category(
    title: SampleCategory.editAndManageData.title,
    icon: Icons.edit,
    backgroundImage: 'assets/category_images/manage_data_background.webp',
  ),
  Category(
    title: SampleCategory.layers.title,
    icon: Icons.layers,
    backgroundImage: 'assets/category_images/layers_background.webp',
  ),
  Category(
    title: SampleCategory.maps.title,
    icon: Icons.map,
    backgroundImage: 'assets/category_images/maps_and_scenes_background.webp',
  ),
  Category(
    title: SampleCategory.routingAndLogistics.title,
    icon: Icons.route,
    backgroundImage:
        'assets/category_images/routing_and_logistics_background.webp',
  ),
  // Category(
  //   title: SampleCategory.scenes.title,
  //   icon: Icons.landscape,
  //   backgroundImage: 'assets/category_images/scenes_background.webp',
  // ),
  Category(
    title: SampleCategory.searchAndQuery.title,
    icon: Icons.search,
    backgroundImage: 'assets/category_images/search_and_query_background.webp',
  ),
  // Category(
  //   title: SampleCategory.utilityNetworks.title,
  //   icon: Icons.electrical_services,
  //   backgroundImage: 'assets/category_images/utility_background.webp',
  // ),
  Category(
    title: SampleCategory.visualization.title,
    icon: Icons.visibility,
    backgroundImage: 'assets/category_images/visualization_background.webp',
  ),
  // Category(
  //   title: SampleCategory.favorites.title,
  //   icon: Icons.favorite,
  //   backgroundImage: 'assets/category_images/maps_and_scenes_background.webp',
  // ),
];
