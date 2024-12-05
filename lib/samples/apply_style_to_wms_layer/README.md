# Apply style to WMS layer

Change the style of a Web Map Service (WMS) layer.

![Image of apply style to WMS layer](apply_style_to_wms_layer.png)

## Use case

Layers hosted on WMS may have different pre-set styles available to apply to them. Swapping between these styles can help during visual examination of the data. For example, increasing the contrast of satellite images can help in identifying urban and agricultural areas within forested areas.

## How to use the sample

Once the layer loads, toggle between the first and second styles of the WMS layer using the dropdown menu.

## How it works

1. Create a `WmsLayer` specifying the URL of the service and the layer names you want `WmsLayer.withUriAndLayerNames(uri: Uri.parse(url), layerNames: names)`.
2. When the layer is done loading, get its list of style strings using `WmsLayer.layerInfos.styles`.
3. Set one of the styles using `WmsSublayer.currentStyle = styles.first`.

## Relevant API

* WmsLayer
* WmsLayerInfo
* WmsSublayer

## About the data

This sample uses a public service managed by the State of Minnesota and provides composite imagery for the state and the surrounding areas.

## Tags

imagery, styles, visualization, WMS
