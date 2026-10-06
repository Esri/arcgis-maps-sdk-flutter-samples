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

The [California Peaks layer](https://arcgis.com/home/item.html?id=f7a011555feb423397601a47a56665d8) contains point features for every mountain peak in California with an elevation that exceeds 14,000 feet (4,267.2 meters) above mean sea level. Each feature contains a predefined popup with information about its associated peak, including an image, chart, and feature table data.

## Tags

feature, feature layer, popup, web map
