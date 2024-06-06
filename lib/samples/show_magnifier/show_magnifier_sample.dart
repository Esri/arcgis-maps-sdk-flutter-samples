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

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

class ShowMagnifierSample extends StatelessWidget {
  const ShowMagnifierSample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => ArcGISMapView.createController()
          ..arcGISMap =
              ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImageryStandard)
          ..arcGISMap!.initialViewpoint = Viewpoint.fromCenter(
            ArcGISPoint(
              x: -110.8258,
              y: 32.154089,
              spatialReference: SpatialReference.wgs84,
            ),
            scale: 2e4,
          )
          ..magnifierEnabled = true,
      ),
    );
  }
}
