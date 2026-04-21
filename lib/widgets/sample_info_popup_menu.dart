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

import 'package:arcgis_maps_sdk_flutter_samples/common/sample_state_support.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SampleInfoPopupMenu extends StatefulWidget {
  const SampleInfoPopupMenu({required this.sample, super.key});
  final Sample sample;

  @override
  State<SampleInfoPopupMenu> createState() => _SampleInfoPopupMenuState();
}

class _SampleInfoPopupMenuState extends State<SampleInfoPopupMenu>
    with SampleStateSupport {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'README',
          child: ListTile(
            leading: Icon(Icons.description),
            title: Text('README'),
          ),
        ),
        PopupMenuItem(
          value: 'Code',
          child: ListTile(leading: Icon(Icons.source), title: Text('Code')),
        ),
        PopupMenuItem(
          value: 'Website',
          child: ListTile(
            leading: Icon(Icons.link_rounded),
            title: Text('Website'),
          ),
        ),
      ],
      onSelected: (result) {
        switch (result) {
          case 'Website':
            _launchSampleUrl();
          default:
            _navigateTo(context, result);
        }
      },
    );
  }

  Future<void> _launchSampleUrl() async {
    if (!await launchUrl(webPageUrl(), mode: LaunchMode.externalApplication)) {
      showMessageDialog('Could not launch ${webPageUrl()}');
    }
  }

  Uri webPageUrl() {
    final formattedKey = widget.sample.key.replaceAll('_', '-');
    final formattedUrl =
        'https://developers.arcgis.com/flutter/sample-code/$formattedKey/';

    return Uri.parse(formattedUrl);
  }

  void _navigateTo(BuildContext context, String selection) {
    // Get the navigation stack, filtering out anything not related to the current sample.
    final stack = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .matches
        .map((match) => match.matchedLocation)
        .where(
          (location) => location.startsWith('/sample/${widget.sample.key}/'),
        );

    // The location we are navigating to.
    final toLocation = '/sample/${widget.sample.key}/$selection';

    if (stack.isEmpty || stack.last.endsWith('/live')) {
      // If there is nothing on the stack from this sample, or if we're on the live
      // running sample, push the location onto the stack.
      context.push(toLocation);
    } else {
      if (stack.last != toLocation) {
        if (stack.contains(toLocation)) {
          // If toLocation is already on the navigation stack, pop() to get to it.
          context.pop();
        } else {
          // Otherwise push the new location onto the navigation stack.
          context.push(toLocation);
        }
      }
    }
  }
}
