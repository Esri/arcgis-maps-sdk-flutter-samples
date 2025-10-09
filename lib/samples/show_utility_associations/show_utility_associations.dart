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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

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

  // A subscription to the viewpoint changed event.
  StreamSubscription<void>? _viewpointChangedSubscription;

  // A flag for when the map view is ready and controls can be used.
  var _ready = false;

  @override
  void initState() {
    super.initState();

    // Set up authentication for the sample server.
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
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: onMapViewReady,
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
          symbol: SimpleLineSymbol(
            style: SimpleLineSymbolStyle.dot,
            color: Colors.green,
            width: 5,
          ),
          values: [UtilityAssociationType.attachment.index],
        ),
        UniqueValue(
          description: 'Connectivity',
          symbol: SimpleLineSymbol(
            style: SimpleLineSymbolStyle.dot,
            color: Colors.red,
            width: 5,
          ),
          values: [UtilityAssociationType.connectivity.index],
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

  //fixme overlay, screenshot

  //fixme comments
  Future<void> addAssociationGraphics() async {
    //fixme need to process only one at a time
    const maxScale = 2000;

    final scale =
        _mapViewController
            .getCurrentViewpoint(ViewpointType.centerAndScale)
            ?.targetScale ??
        double.infinity;
    if (scale > maxScale) return;

    final extent = _mapViewController
        .getCurrentViewpoint(ViewpointType.boundingGeometry)
        ?.targetGeometry
        .extent;
    if (extent == null) return;

    final existingAssociations = _associationsOverlay.graphics
        .map((graphic) => graphic.attributes['GlobalId'])
        .whereType<Guid>()
        .toSet();

    final associations =
        (await _utilityNetwork.getAssociationsWithEnvelope(extent)).where(
          (association) => !existingAssociations.contains(association.globalId),
        );

    if (associations.isEmpty) return;

    print('adding ${associations.length} associations'); //fixme

    final newGraphics = associations.map((association) {
      return Graphic(
        geometry: association.geometry,
        attributes: {
          'GlobalId': association.globalId,
          'AssociationType': association.associationType.index,
        },
      );
    });
    _associationsOverlay.graphics.addAll(newGraphics);
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
