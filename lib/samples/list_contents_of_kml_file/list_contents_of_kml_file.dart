// Copyright 2026 Esri
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

import 'dart:io';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/list_contents_of_kml_file/selected_kml_item_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListContentsOfKmlFile extends StatefulWidget {
  const ListContentsOfKmlFile({super.key});

  @override
  State<ListContentsOfKmlFile> createState() => _ListContentsOfKmlFileState();
}

class _ListContentsOfKmlFileState extends State<ListContentsOfKmlFile>
    with SampleStateSupport {
  // The KML dataset from the test file.
  KmlDataset? _kmlDataset;

  @override
  Widget build(BuildContext context) {
    KmlDocument? kmlDocument;

    if (_kmlDataset == null) {
      // Load the dataset from file.
      _loadKmlDataset().ignore();
    } else {
      // The first and only root node in this dataset is a KML document.
      kmlDocument = _kmlDataset!.rootNodes.first as KmlDocument;
    }

    return Scaffold(
      body: SafeArea(
        left: false,
        right: false,
        child: Stack(
          children: [
            if (kmlDocument == null)
              const Center(child: Text('KML dataset loading...'))
            else
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Text('Expand the KML folders to view child nodes.'),
                        Text('Tap on the nodes to view them in a scene.'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ExpansionTile(
                          title: const Text('Document'),
                          initiallyExpanded: true,
                          childrenPadding: const EdgeInsets.only(left: 16),
                          children: kmlDocument.childNodes
                              .map(_buildKmlNode)
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: _kmlDataset == null),
          ],
        ),
      ),
    );
  }

  Future<void> _loadKmlDataset() async {
    // Create a KML dataset from a local .kmz file.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final kmzFile = File(listPaths.first);
    final kmlDataset = KmlDataset(kmzFile.uri);

    await kmlDataset.load();
    setState(() {
      _kmlDataset = kmlDataset;
    });
  }

  Widget _buildKmlNode(KmlNode node) {
    if (node is KmlFolder) {
      return ExpansionTile(
        title: Text(node.name),
        subtitle: Text('${node.runtimeType}'),
        childrenPadding: const EdgeInsets.only(left: 16),
        children: node.childNodes.map(_buildKmlNode).toList(),
      );
    }

    return ListTile(
      title: Text(node.name),
      subtitle: Text('${node.runtimeType}'),
      onTap: () {
        Navigator.of(context)
            .push<void>(
              MaterialPageRoute<void>(
                builder: (context) => SelectedKmlItemView(
                  kmlDataset: _kmlDataset!,
                  selectedKmlNode: node,
                ),
              ),
            )
            .ignore();
      },
    );
  }
}
