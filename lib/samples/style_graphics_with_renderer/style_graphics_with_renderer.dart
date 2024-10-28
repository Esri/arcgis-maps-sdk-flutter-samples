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

import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/utils/sample_state_support.dart';
import 'package:flutter/material.dart';

class StyleGraphicsWithRenderer extends StatefulWidget {
  const StyleGraphicsWithRenderer({super.key});

  @override
  State<StyleGraphicsWithRenderer> createState() =>
      _StyleGraphicsWithRendererState();
}

class _StyleGraphicsWithRendererState extends State<StyleGraphicsWithRenderer>
    with SampleStateSupport {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcGISMapView(
        controllerProvider: () => _mapViewController,
        onMapViewReady: onMapViewReady,
      ),
    );
  }

  void onMapViewReady() {
    // Create a map with a topographic basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);

    // Add graphics overlays to the mapview controller.
    _mapViewController.graphicsOverlays.add(getPointGraphicsOverlay());
    _mapViewController.graphicsOverlays.add(getLineGraphicsOverlay());
    _mapViewController.graphicsOverlays.add(getEllipseGraphicsOverlay());
    _mapViewController.graphicsOverlays.add(getCurvedPolygonGraphicsOverlay());

    _mapViewController.arcGISMap = map;

    // Combined extent of all the graphic overlays.
    final combinedExtent = Envelope.fromXY(
      spatialReference: SpatialReference.webMercator,
      xMin: -1500000,
      yMin: 000000,
      xMax: 4500000,
      yMax: 5500000,
    );

    _mapViewController.setViewpointGeometry(combinedExtent);
  }

  GraphicsOverlay getPointGraphicsOverlay() {
    // Create a simple marker symbol.
    final pointSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.diamond,
      color: Colors.green,
      size: 10,
    );
    // Create a graphics overlay for the points.
    final pointGraphicsOverlay = GraphicsOverlay();
    // Create and assign a simple renderer to the graphics overlay.
    pointGraphicsOverlay.renderer = SimpleRenderer(symbol: pointSymbol);

    // Create a point graphic with `ArcGISPoint` geometry.
    final pointGeometry = ArcGISPoint(
      x: 40e5,
      y: 40e5,
      spatialReference: SpatialReference.webMercator,
    );
    final pointGraphic = Graphic(geometry: pointGeometry);
    // Add the graphic to the graphics overlay.
    pointGraphicsOverlay.graphics.add(pointGraphic);

    return pointGraphicsOverlay;
  }

  GraphicsOverlay getLineGraphicsOverlay() {
    // Create a simple line symbol.
    final lineSymbol = SimpleLineSymbol(
      color: Colors.blue,
      width: 5,
    );
    // Create a graphics overlay for the line.
    final lineGraphicsOverlay = GraphicsOverlay();
    // Create and assign a simple render to the graphics overlay.
    lineGraphicsOverlay.renderer = SimpleRenderer(symbol: lineSymbol);

    // Create a line with `Polyline` geometry.
    final lineBuilder =
        PolylineBuilder(spatialReference: SpatialReference.webMercator);
    lineBuilder.addPointXY(x: -10e5, y: 40e5);
    lineBuilder.addPointXY(x: 20e5, y: 50e5);
    final lineGraphic = Graphic(geometry: lineBuilder.toGeometry());
    // Add the graphic to the graphics overlay.
    lineGraphicsOverlay.graphics.add(lineGraphic);

    return lineGraphicsOverlay;
  }

  GraphicsOverlay getEllipseGraphicsOverlay() {
    // Create a simple fill symbol.
    final ellipseFillSymbol = SimpleFillSymbol(color: Colors.purple);
    // Create a graphics overlay for the ellipse.
    final ellipseGraphicsOverlay = GraphicsOverlay();
    // Create and assign a simple renderer for the ellipse.
    ellipseGraphicsOverlay.renderer = SimpleRenderer(symbol: ellipseFillSymbol);

    // Create an ellipse graphic.
    final ellipseCenter = ArcGISPoint(
      x: 40e5,
      y: 25e5,
      spatialReference: SpatialReference.webMercator,
    );
    final parameters = GeodesicEllipseParameters(
      axisDirection: -45,
      angularUnit: AngularUnit(unitId: AngularUnitId.degrees),
      center: ellipseCenter,
      linearUnit: LinearUnit(unitId: LinearUnitId.kilometers),
      maxPointCount: 100,
      maxSegmentLength: 20,
      geometryType: GeometryType.polygon,
      semiAxis1Length: 200,
      semiAxis2Length: 400,
    );
    final ellipseGeometry =
        GeometryEngine.ellipseGeodesic(parameters: parameters);
    final ellipseGraphic = Graphic(geometry: ellipseGeometry);

    // Add the graphic to the overlay.
    ellipseGraphicsOverlay.graphics.add(ellipseGraphic);
    return ellipseGraphicsOverlay;
  }

  GraphicsOverlay getCurvedPolygonGraphicsOverlay() {
    // Create a simple fill symbol with outline.
    final curvedLineSymbol = SimpleLineSymbol(color: Colors.black);
    final curvedFillSymbol = SimpleFillSymbol(
      color: Colors.red,
      outline: curvedLineSymbol,
    );
    // Create a graphics overlay for the polygons with curve segments.
    final curvedGraphicsOverlay = GraphicsOverlay();
    // Create and assign a simple renderer to the graphics overlay.
    curvedGraphicsOverlay.renderer = SimpleRenderer(symbol: curvedFillSymbol);

    // Create a heart-shape graphic from Segment.
    final origin = ArcGISPoint(
      x: 40e5,
      y: 5e5,
      spatialReference: SpatialReference.webMercator,
    );
    final heartGeometry = getHeartGeometry(center: origin, sideLength: 10e5);
    final heartGraphic = Graphic(geometry: heartGeometry);

    // Add the graphic to the overlay.
    curvedGraphicsOverlay.graphics.add(heartGraphic);
    return curvedGraphicsOverlay;
  }

  Geometry? getHeartGeometry({
    required ArcGISPoint center,
    required double sideLength,
  }) {
    // The side length should be always greater than 0.
    if (sideLength <= 0) {
      return null;
    }

    final spatialReference = center.spatialReference;
    // The x and y coordinates to simplify the calculation.
    final minX = center.x - 0.5 * sideLength;
    final minY = center.y - 0.5 * sideLength;
    // The radius of the arcs.
    final arcRadius = sideLength * 0.25;

    // Bottom left curve.
    final leftCurveStart =
        ArcGISPoint(x: center.x, y: minY, spatialReference: spatialReference);
    final leftCurveEnd = ArcGISPoint(
      x: minX,
      y: minY + 0.75 * sideLength,
      spatialReference: spatialReference,
    );
    final leftControlPoint1 = ArcGISPoint(
      x: center.x,
      y: minY + 0.25 * sideLength,
      spatialReference: spatialReference,
    );
    final leftControlPoint2 =
        ArcGISPoint(x: minX, y: center.y, spatialReference: spatialReference);
    final leftCurve = CubicBezierSegment(
      startPoint: leftCurveStart,
      controlPoint1: leftControlPoint1,
      controlPoint2: leftControlPoint2,
      endPoint: leftCurveEnd,
      spatialReference: spatialReference,
    );

    // Top left arc.
    final leftArcCenter = ArcGISPoint(
      x: minX + 0.25 * sideLength,
      y: minY + 0.75 * sideLength,
      spatialReference: spatialReference,
    );
    final leftArc =
        EllipticArcSegment.circularEllipticArcWithCenterRadiusAndAngles(
      centerPoint: leftArcCenter,
      radius: arcRadius,
      startAngle: pi,
      centralAngle: -pi,
      spatialReference: spatialReference,
    );

    // Top right arc.
    final rightArcCenter = ArcGISPoint(
      x: minX + 0.75 * sideLength,
      y: minY + 0.75 * sideLength,
      spatialReference: spatialReference,
    );
    final rightArc =
        EllipticArcSegment.circularEllipticArcWithCenterRadiusAndAngles(
      centerPoint: rightArcCenter,
      radius: arcRadius,
      startAngle: pi,
      centralAngle: -pi,
      spatialReference: spatialReference,
    );

    // Bottom right curve.
    final rightCurveStart = ArcGISPoint(
      x: minX + sideLength,
      y: minY + 0.75 * sideLength,
      spatialReference: spatialReference,
    );
    final rightCurveEnd = leftCurveStart;
    final rightControlPoint1 = ArcGISPoint(
      x: minX + sideLength,
      y: center.y,
      spatialReference: spatialReference,
    );
    final rightControlPoint2 = leftControlPoint1;
    final rightCurve = CubicBezierSegment(
      startPoint: rightCurveStart,
      controlPoint1: rightControlPoint1,
      controlPoint2: rightControlPoint2,
      endPoint: rightCurveEnd,
      spatialReference: spatialReference,
    );

    final heart = MutablePart(spatialReference: spatialReference);
    for (final segment in [leftCurve, leftArc, rightArc, rightCurve]) {
      heart.addSegment(segment);
    }

    final heartShape = PolygonBuilder(spatialReference: spatialReference);
    heartShape.parts.addPart(heart);
    return heartShape.toGeometry();
  }
}
