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

import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_detail_page.dart';
import 'package:flutter/material.dart';

class SampleListView extends StatelessWidget {
  const SampleListView({super.key, required this.samples});

  final List<Sample> samples;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: samples.length,
      itemBuilder: (context, index) {
        final sample = samples[index];
        return Card(
          child: ListTile(
            title: Text(sample.title),
            subtitle: Text(sample.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SampleDetailPage(sample: sample),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
