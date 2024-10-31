# Style graphics with renderer

A renderer allows you to change the style of all graphics in a graphics overlay by referencing a single symbol style. A renderer will only affect graphics that do not specify their own symbol style.

![Image of style graphics with renderer](style_graphics_with_renderer.dart)

## Use case

A renderer allows you to change the style of all graphics in an overlay by only changing one copy of the symbol. For example, a user may wish to display a number of graphics on a map of parkland which represent trees, all sharing a common symbol.

## How to use the sample

Pan and zoom on the map to view graphics for points, lines, and polygons (including polygons with curved segments), which are stylized using renderers.

## How it works

1. Create a `GraphicsOverlay` and add it to the `ArcGISMapViewController`.
2. Create a `Graphic`, specifying only a `Geometry`.
3. Create a single `ArcGISSymbol` such as a `SimpleMarkerSymbol`.
4. Create a renderer with `SimpleRenderer()`, passing in an `ArcGISSymbol`.
5. Set the renderer for the `GraphicsOverlay`.

## Relevant API

* CubicBezierSegment
* EllipticArcSegment
* GeodesicEllipseParameters
* Geometry
* GeometryEngine.ellipseGeodesic
* Graphic
* GraphicsOverlay
* MutablePart
* PolygonBuilder
* PolylineBuilder
* SimpleFillSymbol
* SimpleLineSymbol
* SimpleMarkerSymbol
* SimpleRenderer

## Tags

arc, bezier, curve, display, ellipse, graphics, marker, overlay, renderer, segment, symbol, true curve
