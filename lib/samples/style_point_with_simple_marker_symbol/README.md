# Style point with simple marker symbol

Show a simple marker symbol on a map.

![Image of style point with simple marker symbol](style_point_with_simple_marker_symbol.png)

## Use case

Customize the appearance of a point suitable for the data. For example, a point on the map styled with a circle could represent a drilled borehole location, whereas a cross could represent the location of an old coal mine shaft.

## How to use the sample

The sample loads with a predefined simple marker symbol, set as a red circle.

## How it works

1. Create a `SimpleMarkerSymbol`.
2. Create a `Graphic` passing in a `ArcGISPoint` and the simple marker symbol as parameters.
3. Add the graphic to the graphics overlay with `graphicsOverlay.graphics.add(graphic)`.

## Relevant API

* ArcGISPoint
* Graphic
* GraphicsOverlay
* SimpleMarkerSymbol

## Tags

symbol
