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

import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_info_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SampleDetailPage extends StatelessWidget {
  const SampleDetailPage({required this.sample, super.key});

  final Sample sample;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.scaleDown, child: Text(sample.title)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context),
        ),
        actions: [SampleInfoPopupMenu(sample: sample)],
      ),
      body: sample.getSampleWidget(),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    final router = GoRouter.of(context);
    // Check if we came from the resources page
    if (router.state.extra != null) {
      // Skip the previous download page to go to category page directly.
      context.go('/category/${sample.category}');
    } else {
      // Normal back navigation
      context.pop();
    }
  }
}
