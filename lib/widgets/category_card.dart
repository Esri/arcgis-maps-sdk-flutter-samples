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

import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/category.dart';
import 'package:flutter/material.dart';

/// A card widget that displays a SampleCategory.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.category,
    required this.onClick,
    super.key,
  });

  final SampleCategory category;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onClick,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CategoryBackground(category: category),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CategoryIconBackground(category: category),
                  Text(
                    category.title,
                    style: Theme.of(context).textTheme.categoryCardLabelStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryIconBackground extends StatelessWidget {
  const CategoryIconBackground({required this.category, super.key});
  final SampleCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(category.icon, size: 30, color: Colors.white),
    );
  }
}

class CategoryBackground extends StatelessWidget {
  const CategoryBackground({required this.category, super.key});
  final SampleCategory category;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          category.backgroundImage,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(color: Colors.black.withValues(alpha: 0.6)),
      ],
    );
  }
}
