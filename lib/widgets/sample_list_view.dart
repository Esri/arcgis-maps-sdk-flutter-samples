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
import 'package:arcgis_maps_sdk_flutter_samples/widgets/readme_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SampleListView extends StatelessWidget {
  const SampleListView({required this.samples, super.key});

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
            contentPadding: const EdgeInsets.only(left: 20),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'README',
                      child: ListTile(
                        leading: Icon(Icons.description),
                        title: Text('README'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'Website',
                      child: ListTile(
                        leading: Icon(Icons.link_rounded),
                        title: Text('Website'),
                      ),
                    ),
                  ],
              onSelected: (String result) {
                switch (result) {
                  case 'Website':
                    _launchSampleUrl(sample);
                  case 'README':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadmePage(sample: sample),
                      ),
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchSampleUrl(Sample sample) async {
    if (!await launchUrl(
      webPageUrl(sample),
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch ${webPageUrl(sample)}');
    }
  }

  Uri webPageUrl(Sample sample) {
    final formattedKey = sample.key.replaceAll('_', '-');
    final formattedUrl =
        'https://developers.arcgis.com/flutter/sample-code/$formattedKey/';

    return Uri.parse(formattedUrl);
  }
}
