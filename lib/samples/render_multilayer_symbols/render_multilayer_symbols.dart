//
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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';

class RenderMultilayerSymbols extends StatefulWidget {
  const RenderMultilayerSymbols({super.key});

  @override
  State<RenderMultilayerSymbols> createState() =>
      _RenderMultilayerSymbolsState();
}

class _RenderMultilayerSymbolsState extends State<RenderMultilayerSymbols>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add a map view to the widget tree and set a controller.
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with a light gray basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISLightGray);
    _mapViewController.arcGISMap = map;

    // Set an initial viewpoint.
    map.initialViewpoint = Viewpoint.fromTargetExtent(
      Envelope.fromPoints(
        ArcGISPoint(x: -180, y: -90, spatialReference: SpatialReference.wgs84),
        ArcGISPoint(x: 180, y: 90, spatialReference: SpatialReference.wgs84),
      ),
    );

    // Load the multilayer symbol graphics onto the map.
    final overlay = createMultilayerGraphics();
    _mapViewController.graphicsOverlays.add(overlay);
  }

  // Helper method to create a simple text symbol for labeling the symbol categories.
  TextSymbol labelSymbol(String text) {
    return TextSymbol(text: text, size: 10)..backgroundColor = Colors.white;
  }

  // Prepare a graphics overlay with graphics that demonstrate the various multilayer symbol types.
  GraphicsOverlay createMultilayerGraphics() {
    // A common offset value to use for separating the symbol layers in the display.
    const offset = 20.0;

    // Create a graphics overlay to hold the multilayer symbol graphics.
    final overlay = GraphicsOverlay();

    // MultilayerPoint - simple markers.
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: -150,
          y: 50,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: labelSymbol('MultilayerPoint\nSimple markers'),
      ),
    );

    // A diamond.
    final diamondGeometry = Geometry.fromJsonString(
      '{"rings":[[[0.0,2.5],[2.5,0.0],[0.0,-2.5],[-2.5,0.0],[0.0,2.5]]]}',
    );
    final diamondElement = VectorMarkerSymbolElement(
      geometry: diamondGeometry,
      multilayerSymbol: MultilayerPolygonSymbol(
        symbolLayers: [SolidFillSymbolLayer(color: Colors.red)],
      ),
    );
    final diamondLayer = VectorMarkerSymbolLayer(
      vectorMarkerSymbolElements: [diamondElement],
    );
    final diamondPointSymbol = MultilayerPointSymbol(
      symbolLayers: [diamondLayer],
    );
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: -150,
          y: 20,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: diamondPointSymbol,
      ),
    );

    // A triangle.
    final triangleGeometry = Geometry.fromJsonString(
      '{"rings":[[[0.0,5.0],[5,-5.0],[-5,-5.0],[0.0,5.0]]]}',
    );
    final triangleElement = VectorMarkerSymbolElement(
      geometry: triangleGeometry,
      multilayerSymbol: MultilayerPolygonSymbol(
        symbolLayers: [SolidFillSymbolLayer(color: Colors.red)],
      ),
    );
    final triangleLayer = VectorMarkerSymbolLayer(
      vectorMarkerSymbolElements: [triangleElement],
    );
    final trianglePointSymbol = MultilayerPointSymbol(
      symbolLayers: [triangleLayer],
    );
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: -150,
          y: 20 - offset,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: trianglePointSymbol,
      ),
    );

    // An X shape.
    final xGeometry = Geometry.fromJsonString(
      '{"paths":[[[-1,1],[0,0],[1,-1]],[[1,1],[0,0],[-1,-1]]]}',
    );
    final xElement = VectorMarkerSymbolElement(
      geometry: xGeometry,
      multilayerSymbol: MultilayerPolylineSymbol(
        symbolLayers: [SolidStrokeSymbolLayer(width: 1, color: Colors.red)],
      ),
    );
    final xLayer = VectorMarkerSymbolLayer(
      vectorMarkerSymbolElements: [xElement],
    );
    final xPointSymbol = MultilayerPointSymbol(symbolLayers: [xLayer]);
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: -150,
          y: 20 - (2 * offset),
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: xPointSymbol,
      ),
    );

    // MultilayerPoint - picture markers.
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: -80,
          y: 50,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: labelSymbol('MultilayerPoint\nPicture markers'),
      ),
    );

    // Picture marker symbol from a URL.
    final campsiteMarker = PictureMarkerSymbolLayer.withUri(
      Uri.parse(
        'https://static.arcgis.com/images/Symbols/OutdoorRecreation/Camping.png',
      ),
    )..size = 30;
    final campsiteSymbol = MultilayerPointSymbol(
      symbolLayers: [campsiteMarker],
    );
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: -80,
          y: 20,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: campsiteSymbol,
      ),
    );

    // Picture marker symbol from an asset.
    ArcGISImage.fromAsset('assets/pin_circle_red.png').then((pinImage) {
      final pinMarker = PictureMarkerSymbolLayer.withImage(pinImage)..size = 30;
      final pinSymbol = MultilayerPointSymbol(symbolLayers: [pinMarker]);
      overlay.graphics.add(
        Graphic(
          geometry: ArcGISPoint(
            x: -80,
            y: 20 - offset - 10,
            spatialReference: SpatialReference.wgs84,
          ),
          symbol: pinSymbol,
        ),
      );
    }).ignore();

    // Multilayer - polylines.
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: 0,
          y: 50,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: labelSymbol('Multilayer\nPolyline'),
      ),
    );

    // Dash, dot, dot.
    var polylineBuilder =
        PolylineBuilder(spatialReference: SpatialReference.wgs84)
          ..addPointXY(x: -30, y: 20)
          ..addPointXY(x: 30, y: 20);
    var stroke = SolidStrokeSymbolLayer(
      width: 3,
      color: Colors.red,
      geometricEffects: [
        DashGeometricEffect(dashTemplate: const [4, 6, 0.5, 6, 0.5, 6]),
      ],
    )..capStyle = StrokeSymbolLayerCapStyle.round;
    overlay.graphics.add(
      Graphic(
        geometry: polylineBuilder.toGeometry(),
        symbol: MultilayerPolylineSymbol(symbolLayers: [stroke]),
      ),
    );

    // Dashes.
    polylineBuilder = PolylineBuilder(spatialReference: SpatialReference.wgs84)
      ..addPointXY(x: -30, y: 20 - offset)
      ..addPointXY(x: 30, y: 20 - offset);
    stroke = SolidStrokeSymbolLayer(
      width: 3,
      color: Colors.red,
      geometricEffects: [
        DashGeometricEffect(dashTemplate: const [4, 6]),
      ],
    )..capStyle = StrokeSymbolLayerCapStyle.round;
    overlay.graphics.add(
      Graphic(
        geometry: polylineBuilder.toGeometry(),
        symbol: MultilayerPolylineSymbol(symbolLayers: [stroke]),
      ),
    );

    // Dash, dot.
    polylineBuilder = PolylineBuilder(spatialReference: SpatialReference.wgs84)
      ..addPointXY(x: -30, y: 20 - (2 * offset))
      ..addPointXY(x: 30, y: 20 - (2 * offset));
    stroke = SolidStrokeSymbolLayer(
      width: 3,
      color: Colors.red,
      geometricEffects: [
        DashGeometricEffect(dashTemplate: const [7, 9, 0.5, 9]),
      ],
    )..capStyle = StrokeSymbolLayerCapStyle.round;
    overlay.graphics.add(
      Graphic(
        geometry: polylineBuilder.toGeometry(),
        symbol: MultilayerPolylineSymbol(symbolLayers: [stroke]),
      ),
    );

    // Multilayer - polygons.
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: 65,
          y: 50,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: labelSymbol('Multilayer\nPolygon'),
      ),
    );

    final hatchStroke = SolidStrokeSymbolLayer(width: 2, color: Colors.red);
    final outlineStroke = SolidStrokeSymbolLayer(width: 1);

    // Cross-hatched diagonal lines.
    var polygonBuilder =
        PolygonBuilder(spatialReference: SpatialReference.wgs84)
          ..addPointXY(x: 60, y: 25)
          ..addPointXY(x: 70, y: 25)
          ..addPointXY(x: 70, y: 20)
          ..addPointXY(x: 60, y: 20);
    final diagonalStroke1 = HatchFillSymbolLayer(
      polylineSymbol: MultilayerPolylineSymbol(symbolLayers: [hatchStroke]),
      angle: 45,
    )..separation = 9;
    final diagonalStroke2 = HatchFillSymbolLayer(
      polylineSymbol: MultilayerPolylineSymbol(symbolLayers: [hatchStroke]),
      angle: -45,
    )..separation = 9;
    overlay.graphics.add(
      Graphic(
        geometry: polygonBuilder.toGeometry(),
        symbol: MultilayerPolygonSymbol(
          symbolLayers: [diagonalStroke1, diagonalStroke2, outlineStroke],
        ),
      ),
    );

    // Hatched diagonal lines.
    polygonBuilder = PolygonBuilder(spatialReference: SpatialReference.wgs84)
      ..addPointXY(x: 60, y: 25 - offset)
      ..addPointXY(x: 70, y: 25 - offset)
      ..addPointXY(x: 70, y: 20 - offset)
      ..addPointXY(x: 60, y: 20 - offset);
    final forwardDiagonal = HatchFillSymbolLayer(
      polylineSymbol: MultilayerPolylineSymbol(symbolLayers: [hatchStroke]),
      angle: -45,
    )..separation = 9;
    overlay.graphics.add(
      Graphic(
        geometry: polygonBuilder.toGeometry(),
        symbol: MultilayerPolygonSymbol(
          symbolLayers: [forwardDiagonal, outlineStroke],
        ),
      ),
    );

    // Hatched vertical lines.
    polygonBuilder = PolygonBuilder(spatialReference: SpatialReference.wgs84)
      ..addPointXY(x: 60, y: 25 - (2 * offset))
      ..addPointXY(x: 70, y: 25 - (2 * offset))
      ..addPointXY(x: 70, y: 20 - (2 * offset))
      ..addPointXY(x: 60, y: 20 - (2 * offset));
    final vertical = HatchFillSymbolLayer(
      polylineSymbol: MultilayerPolylineSymbol(symbolLayers: [hatchStroke]),
      angle: 90,
    )..separation = 9;
    overlay.graphics.add(
      Graphic(
        geometry: polygonBuilder.toGeometry(),
        symbol: MultilayerPolygonSymbol(
          symbolLayers: [vertical, outlineStroke],
        ),
      ),
    );

    // More multilayer symbols.
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: 130,
          y: 50,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: labelSymbol('More Multilayer\nSymbols'),
      ),
    );

    // Complex multilayer point symbol.
    final orangeSquareLayer =
        VectorMarkerSymbolLayer(
            vectorMarkerSymbolElements: [
              VectorMarkerSymbolElement(
                geometry: Envelope.fromPoints(
                  ArcGISPoint(
                    x: -0.5,
                    y: -0.5,
                    spatialReference: SpatialReference.wgs84,
                  ),
                  ArcGISPoint(
                    x: 0.5,
                    y: 0.5,
                    spatialReference: SpatialReference.wgs84,
                  ),
                ),
                multilayerSymbol: MultilayerPolygonSymbol(
                  symbolLayers: [
                    SolidFillSymbolLayer(color: Colors.orange),
                    SolidStrokeSymbolLayer(width: 2, color: Colors.blue),
                  ],
                ),
              ),
            ],
          )
          ..size = 11
          ..anchor = SymbolAnchor(
            x: -4,
            y: -6,
            placementMode: SymbolAnchorPlacementMode.absolute,
          );

    final blackSquareLayer =
        VectorMarkerSymbolLayer(
            vectorMarkerSymbolElements: [
              VectorMarkerSymbolElement(
                geometry: Envelope.fromPoints(
                  ArcGISPoint(
                    x: -0.5,
                    y: -0.5,
                    spatialReference: SpatialReference.wgs84,
                  ),
                  ArcGISPoint(
                    x: 0.5,
                    y: 0.5,
                    spatialReference: SpatialReference.wgs84,
                  ),
                ),
                multilayerSymbol: MultilayerPolygonSymbol(
                  symbolLayers: [
                    SolidFillSymbolLayer(color: Colors.black),
                    SolidStrokeSymbolLayer(width: 2, color: Colors.deepOrange),
                  ],
                ),
              ),
            ],
          )
          ..size = 6
          ..anchor = SymbolAnchor(
            x: 2,
            y: 1,
            placementMode: SymbolAnchorPlacementMode.absolute,
          );

    final purpleSquareLayer =
        VectorMarkerSymbolLayer(
            vectorMarkerSymbolElements: [
              VectorMarkerSymbolElement(
                geometry: Envelope.fromPoints(
                  ArcGISPoint(
                    x: -0.5,
                    y: -0.5,
                    spatialReference: SpatialReference.wgs84,
                  ),
                  ArcGISPoint(
                    x: 0.5,
                    y: 0.5,
                    spatialReference: SpatialReference.wgs84,
                  ),
                ),
                multilayerSymbol: MultilayerPolygonSymbol(
                  symbolLayers: [
                    SolidFillSymbolLayer(color: Colors.transparent),
                    SolidStrokeSymbolLayer(width: 2, color: Colors.purple),
                  ],
                ),
              ),
            ],
          )
          ..size = 14
          ..anchor = SymbolAnchor(
            x: 4,
            y: 2,
            placementMode: SymbolAnchorPlacementMode.absolute,
          );

    final hexagonGeometry = Geometry.fromJsonString(
      '{"rings":[[[-2.89,5.0],[2.89,5.0],[5.77,0.0],[2.89,-5.0],[-2.89,-5.0],[-5.77,0.0],[-2.89,5.0]]]}',
    );
    final hexagonLayer = VectorMarkerSymbolLayer(
      vectorMarkerSymbolElements: [
        VectorMarkerSymbolElement(
          geometry: hexagonGeometry,
          multilayerSymbol: MultilayerPolygonSymbol(
            symbolLayers: [
              SolidFillSymbolLayer(color: Colors.yellow),
              SolidStrokeSymbolLayer(width: 2),
            ],
          ),
        ),
      ],
    )..size = 35;

    final complexPointSymbol = MultilayerPointSymbol(
      symbolLayers: [
        hexagonLayer,
        orangeSquareLayer,
        blackSquareLayer,
        purpleSquareLayer,
      ],
    );
    overlay.graphics.add(
      Graphic(
        geometry: ArcGISPoint(
          x: 130,
          y: 20,
          spatialReference: SpatialReference.wgs84,
        ),
        symbol: complexPointSymbol,
      ),
    );

    // Complex multilayer polygon symbol.
    final complexOutline = SolidStrokeSymbolLayer(width: 7)
      ..capStyle = StrokeSymbolLayerCapStyle.round;
    final complexInnerStroke = SolidStrokeSymbolLayer(
      width: 5,
      color: Colors.yellow,
    )..capStyle = StrokeSymbolLayerCapStyle.round;
    final complexDashes = SolidStrokeSymbolLayer(
      width: 1,
      geometricEffects: [
        DashGeometricEffect(dashTemplate: const [5, 3]),
      ],
    )..capStyle = StrokeSymbolLayerCapStyle.square;

    final complexPolygonBuilder =
        PolygonBuilder(spatialReference: SpatialReference.wgs84)
          ..addPointXY(x: 120, y: 0)
          ..addPointXY(x: 140, y: 0)
          ..addPointXY(x: 140, y: -10)
          ..addPointXY(x: 120, y: -10);
    overlay.graphics.add(
      Graphic(
        geometry: complexPolygonBuilder.toGeometry(),
        symbol: MultilayerPolygonSymbol(
          symbolLayers: [
            SolidFillSymbolLayer(color: Colors.red),
            complexOutline,
            complexInnerStroke,
            complexDashes,
          ],
        ),
      ),
    );

    // Complex multilayer polyline symbol.
    final complexLineBuilder =
        PolylineBuilder(spatialReference: SpatialReference.wgs84)
          ..addPointXY(x: 120, y: -25)
          ..addPointXY(x: 140, y: -25);
    overlay.graphics.add(
      Graphic(
        geometry: complexLineBuilder.toGeometry(),
        symbol: MultilayerPolylineSymbol(
          symbolLayers: [complexOutline, complexInnerStroke, complexDashes],
        ),
      ),
    );

    // Return the completed graphics overlay.
    return overlay;
  }
}
