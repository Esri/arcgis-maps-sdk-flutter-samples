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

import 'dart:async';
import 'dart:typed_data';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ShowUtilityAssociations extends StatefulWidget {
  const ShowUtilityAssociations({super.key});

  @override
  State<ShowUtilityAssociations> createState() =>
      _ShowUtilityAssociationsState();
}

class _ShowUtilityAssociationsState extends State<ShowUtilityAssociations>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  // The utility network.
  late UtilityNetwork _utilityNetwork;

  // A graphics overlay to display the utility associations.
  final _associationsOverlay = GraphicsOverlay();

  // A symbol for attachment associations.
  final _attachmentSymbol = SimpleLineSymbol(
    style: SimpleLineSymbolStyle.dot,
    color: Colors.green,
    width: 5,
  );

  // A symbol for connectivity associations.
  final _connectivitySymbol = SimpleLineSymbol(
    style: SimpleLineSymbolStyle.dot,
    color: Colors.red,
    width: 5,
  );

  // A subscription to the viewpoint changed event.
  StreamSubscription<void>? _viewpointChangedSubscription;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();

    // Set up authentication for the sample server.
    // Note: Never hardcode login information in a production application.
    // This is done solely for the sake of the sample.
    ArcGISEnvironment
        .authenticationManager
        .arcGISAuthenticationChallengeHandler = _TokenChallengeHandler(
      'viewer01',
      'I68VGU^nMurF',
    );
  }

  @override
  void dispose() {
    // Resets the URL session challenge handler to use default handling
    // and removes all credentials.
    ArcGISEnvironment
            .authenticationManager
            .arcGISAuthenticationChallengeHandler =
        null;
    ArcGISEnvironment.authenticationManager.arcGISCredentialStore.removeAll();

    _viewpointChangedSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Add a map view to the widget tree and set a controller.
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
          ),
          // Add a legend for the association types.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      const Text('Utility association types'),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.fromLTRB(5, 5, 50, 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SwatchImage(symbol: _attachmentSymbol),
                                const Text('Attachment'),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SwatchImage(symbol: _connectivitySymbol),
                                const Text('Connectivity'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Display a progress indicator and prevent interaction until state is ready.
          LoadingIndicator(visible: !_ready),
        ],
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map from a PortalItem that contains the Naperville Electric Map.
    final portalItem = PortalItem.withPortalAndItemId(
      portal: Portal(
        Uri.parse('https://sampleserver7.arcgisonline.com/portal/'),
        connection: PortalConnection.authenticated,
      ),
      itemId: 'be0e4637620a453584118107931f718b',
    );
    final map = ArcGISMap.withItem(portalItem);

    // Load the map to make the utility network available.
    await map.load();

    // Set the initial viewpoint in the utility network area.
    map.initialViewpoint = Viewpoint.withLatLongScale(
      latitude: 41.8057655,
      longitude: -88.1489692,
      scale: 70.5310735,
    );

    // Set the map on the controller.
    _mapViewController.arcGISMap = map;

    // Get the utility network.
    _utilityNetwork = map.utilityNetworks.first;
    await _utilityNetwork.load();

    // Prepare the associations graphics overlay, with symbols for each type.
    _associationsOverlay.renderer = UniqueValueRenderer(
      fieldNames: ['AssociationType'],
      uniqueValues: [
        UniqueValue(
          description: 'Attachment',
          symbol: _attachmentSymbol,
          values: [UtilityAssociationType.attachment.name],
        ),
        UniqueValue(
          description: 'Connectivity',
          symbol: _connectivitySymbol,
          values: [UtilityAssociationType.connectivity.name],
        ),
      ],
    );
    _mapViewController.graphicsOverlays.add(_associationsOverlay);

    // Add a handler for viewpoint changes to update the associations.
    _viewpointChangedSubscription = _mapViewController.onViewpointChanged
        .listen((_) => addAssociationGraphics());
    await addAssociationGraphics();

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  Future<void> addAssociationGraphics() async {
    // Get the current scale.
    final scale =
        _mapViewController
            .getCurrentViewpoint(ViewpointType.centerAndScale)
            ?.targetScale ??
        double.infinity;

    // Don't add graphics if the scale is too large.
    const maxScale = 2000;
    if (scale > maxScale) return;

    // Get the current extent.
    final extent = _mapViewController
        .getCurrentViewpoint(ViewpointType.boundingGeometry)
        ?.targetGeometry
        .extent;
    if (extent == null) return;

    // Find the associations in the current extent.
    final associations = await _utilityNetwork.getAssociationsWithEnvelope(
      extent,
    );

    // Filter out associations that are already being displayed.
    final existingAssociations = _associationsOverlay.graphics
        .map((graphic) => graphic.attributes['GlobalId'])
        .whereType<Guid>()
        .toSet();
    final newAssociations = associations.where(
      (association) => !existingAssociations.contains(association.globalId),
    );

    // Add graphics for the new associations.
    _associationsOverlay.graphics.addAll(
      newAssociations.map(
        (association) => Graphic(
          geometry: association.geometry,
          attributes: {
            'GlobalId': association.globalId,
            'AssociationType': association.associationType.name,
          },
        ),
      ),
    );
  }
}

// Handle the token authentication challenge callback.
class _TokenChallengeHandler implements ArcGISAuthenticationChallengeHandler {
  _TokenChallengeHandler(this.username, this.password);
  final String username;
  final String password;

  @override
  Future<void> handleArcGISAuthenticationChallenge(
    ArcGISAuthenticationChallenge challenge,
  ) async {
    final credential = await TokenCredential.createWithChallenge(
      challenge,
      username: username,
      password: password,
    );
    challenge.continueWithCredential(credential);
  }
}

// A widget that creates and displays a swatch image for a symbol.
class SwatchImage extends StatefulWidget {
  const SwatchImage({
    required this.symbol,
    this.width = 10,
    this.height = 10,
    super.key,
  });

  final ArcGISSymbol symbol;
  final double width;
  final double height;

  @override
  State<SwatchImage> createState() => _SwatchImageState();
}

class _SwatchImageState extends State<SwatchImage> {
  // A Completer that completes when the swatch image is ready.
  final _swatchCompleter = Completer<Uint8List>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Get the device pixel ratio after the first frame to ensure it is accurate.
      final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

      // Create a swatch image from the symbol.
      widget.symbol
          .createSwatch(
            screenScale: devicePixelRatio,
            width: widget.width,
            height: widget.height,
          )
          .then((image) {
            // Signal that the swatch image is ready.
            _swatchCompleter.complete(image.getEncodedBuffer());
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _swatchCompleter.future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // The swatch image is ready -- display it.
          return Image.memory(snapshot.data!);
        }

        // Until the image is ready, reserve space to avoid layout changes.
        return SizedBox(width: widget.width, height: widget.height);
      },
    );
  }
}
