# Create planar and geodetic buffers

Create a buffer around a map point and display the results as a graphic.

![Image of create planar and geodetic buffers](create_planar_and_geodetic_buffers.png)

## Use case

Creating buffers is a core concept in GIS proximity analysis that allows you to visualize and locate geographic features contained within a polygon. For example, suppose you wanted to visualize areas of your city where alcohol sales are prohibited because they are within 500 meters of a school. The first step in this proximity analysis would be to generate 500 meter buffer polygons around all schools in the city. Any such businesses you find inside one of the resulting polygons are violating the law.

## How to use the sample

1. Tap on the map.
2. A planar and a geodetic buffer will be created at the tap location using the distance (miles) specified.
3. Continue tapping to create additional buffers. Notice that buffers closer to the equator appear similar in size. As you move north or south from the equator, however, the geodetic polygons become much larger. Geodetic polygons are in fact a better representation of the true shape and size of the buffer.
4. Tap `Clear` to remove all buffers and start again.

## How it works

1. The map `ArcGISPoint` for a tap on the display is captured.
2. The static method `GeometryEngine.buffer` is called to create a planar buffer polygon from the map location and distance.
3. Another static method, `GeometryEngine.bufferGeodetic`, is called to create a geodetic buffer polygon using the same inputs.
4. The polygon results (and tap location) are displayed in the map view with different symbols in order to highlight the difference between the buffer techniques due to the spatial reference used in the planar calculation.

## Relevant API

* GeometryEngine.buffer
* GeometryEngine.bufferGeodetic
* GraphicsOverlay

## Additional information

Buffers can be generated as either `planar` (flat - coordinate space of the map's spatial reference) or `geodetic` (technique that considers the curved shape of the Earth's surface, which is generally a more accurate representation). In general, distortion in the map increases as you move away from the standard parallels of the spatial reference's projection. This map is in Web Mercator so areas near the equator are the most accurate. As you move the buffer location north or south from that line, you'll see a greater difference in the polygon size and shape. Planar operations are generally faster, but performance improvement may only be noticeable for large operations (buffering a great number or complex geometry).

For more information about using buffer analysis, see the topic How [Buffer (Analysis) works](https://pro.arcgis.com/en/pro-app/latest/tool-reference/analysis/how-buffer-analysis-works.htm) in the ArcGIS Pro documentation.

## Tags

analysis, buffer, euclidean, geodetic, geometry, planar
