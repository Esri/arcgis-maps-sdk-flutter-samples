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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xml/xml.dart';

class ApplyDictionaryRendererToGraphicsOverlay extends StatefulWidget {
  const ApplyDictionaryRendererToGraphicsOverlay({super.key});

  @override
  State<ApplyDictionaryRendererToGraphicsOverlay> createState() =>
      _ApplyDictionaryRendererToGraphicsOverlayState();
}

class _ApplyDictionaryRendererToGraphicsOverlayState
    extends State<ApplyDictionaryRendererToGraphicsOverlay>
    with SampleStateSupport {
  // Create a controller for the scene view.
  final _sceneViewController = ArcGISSceneView.createController();

  // The graphics overlay for displaying the message graphics on the scene.
  final _graphicsOverlay = GraphicsOverlay();

  // A flag for when the scene view is ready and controls can be used.
  var _ready = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            // Add a scene view to the widget tree and set a controller.
            ArcGISSceneView(
              controllerProvider: () => _sceneViewController,
              onSceneViewReady: onSceneViewReady,
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            LoadingIndicator(visible: !_ready),
          ],
        ),
      ),
    );
  }

  Future<void> onSceneViewReady() async {
    // Create a scene with a topographic basemap style.
    final scene = ArcGISScene.withBasemapStyle(.arcGISTopographic);
    _sceneViewController.arcGISScene = scene;

    // Set the dictionary renderer on the overlay.
    _graphicsOverlay.renderer = await getMIL2525DRenderer();

    // Parse the MIL-STD-2525D XML and add graphics to the overlay.
    final graphics = await generateMessageGraphics();
    _graphicsOverlay.graphics.addAll(graphics);

    // Attach the overlay to the scene view.
    _sceneViewController.graphicsOverlays.add(_graphicsOverlay);

    // Set a viewpoint camera to the scene view using the extent of the graphics overlay.
    final extent = _graphicsOverlay.extent;
    if (extent != null) {
      final camera = Camera.withLookAtPoint(
        lookAtPoint: extent.center,
        distance: 15000,
        heading: 0,
        pitch: 70,
        roll: 0,
      );
      _sceneViewController.setViewpointCamera(camera);
    }

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  // Creates a dictionary renderer for styling with MIL-STD-2525D symbols.
  Future<DictionaryRenderer> getMIL2525DRenderer() async {
    // Create a dictionary symbol style form a dictionary style portal item.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal.arcGISOnline(),
      itemId: 'd815f3bdf6e6452bb8fd153b654c94ca',
    );
    final dictionarySymbolStyle = DictionarySymbolStyle.withPortalItem(
      portalItem,
    );
    await dictionarySymbolStyle.load();

    // Uses the "Ordered Anchor Points" for the symbol style draw rule.
    final drawRuleConfiguration = dictionarySymbolStyle.configurations
        .firstWhere((item) => item.name == 'model');
    drawRuleConfiguration.value = 'ORDERED ANCHOR POINTS';

    return DictionaryRenderer(dictionarySymbolStyle: dictionarySymbolStyle);
  }

  // Load and Create MessageGraphics.
  Future<List<Graphic>> generateMessageGraphics() async {
    // Create file reference for the MIL-STD-2525D XML File.
    final listPaths = GoRouter.of(context).state.extra! as List<String>;
    final mil2525XMLFile = File(listPaths.first);

    // Read the XML as a string and parse it into a list of Message objects.
    final xmlString = await mil2525XMLFile.readAsString();
    final parser = _MessageParser()..parse(xmlString);

    // Convert each parsed message into a Graphic.
    return parser.messages
        .map<Graphic?>((message) {
          final wkid = message.wkid;
          // Skip messages without a usable WKID.
          if (wkid == null) return null;

          final spatialReference = SpatialReference(wkid: wkid);
          final builder = MultipointBuilder(spatialReference: spatialReference);
          for (final coord in message.controlPoints) {
            builder.points.addPointXY(x: coord.x, y: coord.y);
          }
          final multipoint = builder.toGeometry() as Multipoint;

          return Graphic(geometry: multipoint, attributes: message.other);
        })
        .whereType<Graphic>()
        .toList(growable: false);
  }
}

/// The parsed values from a single `<message>` element of the XML file.
class _Message {
  /// The x and y values from the `<_control_points>` element.
  List<({double x, double y})> controlPoints = [];

  /// The integer value of the `<_wkid>` element.
  int? wkid;

  /// Every other child element name → its text content.
  Map<String, dynamic> other = {};
}

/// A DOM-based XML parser for the MIL-STD-2525D messages file.
class _MessageParser {
  final List<_Message> messages = [];

  void parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    // Iterate every <message> element (children of the root <messages>).
    for (final messageNode in document.findAllElements('message')) {
      final message = _Message();

      for (final child in messageNode.childElements) {
        final name = child.name.local;
        final text = child.innerText;

        switch (name) {
          case '_control_points':
            // The text looks like "x1,y1;x2,y2;...".
            message.controlPoints = text
                .split(';')
                .where((pair) => pair.contains(','))
                .map((pair) {
                  final parts = pair.split(',');
                  return (
                    x: double.parse(parts.first.trim()),
                    y: double.parse(parts.last.trim()),
                  );
                })
                .toList();
          case '_wkid':
            message.wkid = int.tryParse(text.trim());
          default:
            message.other[name] = text;
        }
      }

      messages.add(message);
    }
  }
}
