# Add raster from file

Create and use a raster layer made from a local raster file.

![Image of add raster from file](add_raster_from_file.png)

## Use case

Rasters can be digital aerial photographs, imagery from satellites, digital pictures, or even scanned maps. An end-user will frequently need to import raster files acquired through various data-collection methods into their map to view and analyze the data.

## How to use the sample

When the sample starts, a raster will be loaded from a file and displayed in the map view.

## How it works

1. Create a `Raster` from a raster file.
2. Create a `RasterLayer` from the raster.
3. Add it as an operational layer with `map.operationalLayers.add(rasterLayer)`.

## Relevant API

* Raster
* RasterLayer

## Additional information

See the topic [What is raster data?](https://pro.arcgis.com/en/pro-app/latest/help/data/imagery/introduction-to-raster-data.htm) in the *ArcGIS Pro* documentation for more information about raster images.

## Tags

data, image, import, layer, raster, visualization
