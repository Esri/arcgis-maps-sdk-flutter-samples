import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_info_popup_menu.dart';
import 'package:flutter/material.dart';

class SampleDetailPage extends StatelessWidget {
  const SampleDetailPage({required this.sample, super.key});

  final Sample sample;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(fit: BoxFit.scaleDown, child: Text(sample.title)),
        actions: [SampleInfoPopupMenu(sample: sample)],
      ),
      body: sample.getSampleWidget(),
    );
  }
}
