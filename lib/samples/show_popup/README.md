# Show popup

Show predefined popups from a web map.

![Image of show popup](show_popup.png)

## Use case

Many web maps contain predefined popups which are used to display the attributes associated with each feature layer in the map, such as hiking trails, land values, or unemployment rates. You can display text, attachments, images, charts, and web links. Rather than creating new popups to display information, you can easily access and display the predefined popups.

## How to use the sample

Tap on the features to prompt a popup that displays information about the feature.

## How it works

1. Create and load an `ArcGISMap` instance from a `PortalItem` of a web map.
2. Set the map to an `ArcGISMapViewController`.
3. Use the `ArcGISMapViewController.identifyLayers()` method to identify the top-most feature.
4. Create a `PopupView` with the result's first popup.

## Relevant API

* ArcGISMap
* IdentifyLayerResult
* PopupView

## About the data

This sample uses a [web map](https://www.arcgis.com/home/item.html?id=fb788308ea2e4d8682b9c05ef641f273) that displays reported incidents in San Francisco.

## Tags

feature, feature layer, popup, web map
