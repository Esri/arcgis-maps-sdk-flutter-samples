import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/code_view_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/readme_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SampleInfoPopupMenu extends StatelessWidget {
  const SampleInfoPopupMenu({required this.sample, super.key});
  final Sample sample;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
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
          case 'README':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReadmePage(sample: sample),
              ),
            );
          case 'Code':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CodeViewPage(sample: sample),
              ),
            );
        }
      },
    );
  }

  Future<void> _launchSampleUrl() async {
    if (!await launchUrl(webPageUrl(), mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch ${webPageUrl()}');
    }
  }

  Uri webPageUrl() {
    final formattedKey = sample.key.replaceAll('_', '-');
    final formattedUrl =
        'https://developers.arcgis.com/flutter/sample-code/$formattedKey/';

    return Uri.parse(formattedUrl);
  }
}
