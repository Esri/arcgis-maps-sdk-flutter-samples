# Control annotation sublayer visibility

Use annotation sublayers to gain finer control of annotation layer subtypes.

![Image of control annotation sublayer visibility](control-annotation-sublayer-visibility.png)

## Use case

Annotation, which differs from labels by having a fixed place and size, is typically only relevant at particular scales. Annotation sublayers allow for finer control of annotation by allowing properties (like visibility in the map and legend) to be set and others to be read (like name) on subtypes of an annotation layer.

An annotation dataset which marks valves as "Opened" or "Closed", might be set to display the "Closed" valves over a broader range of scales than the "Opened" valves, if the "Closed" data is considered more relevant by the map's author. Regardless, the user can be given a manual option to set visibility of annotation sublayers on and off, if required.

## How to use the sample

Start the sample and take note of the visibility of the annotation. Zoom in and out to see the annotation turn on and off based on scale ranges set on the data.

Use the checkboxes to manually set "Open" and "Closed" annotation sublayers visibility to on or off.

## How it works

1. Load a `MobileMapPackage` that contains `AnnotationSublayer`.
2. Get the sublayers from the map package's layers by calling `sublayer.getSubLayerContents.get(i)`.
3. You can toggle the visibility of each sublayer manually using `sublayer.setVisible()`.
4. To determine if a sublayer is visible at the current scale of the `MapView`, use `sublayer.isVisibleAtScale()`, by passing in the map's current scale.
 
## Relevant API

* AnnotationLayer
* AnnotationSublayer
* LayerContent

## Offline data

1. Download the [GasDeviceAnno](https://arcgisruntime.maps.arcgis.com/home/item.html?id=b87307dcfb26411eb2e92e1627cb615b) mobile map package from ArcGIS Online.
2. Extract the contents of the downloaded zip file to disk.
3. Open your command prompt and navigate to the folder where you extracted the contents of the data from step 1.
4. Execute the following command:
`adb push GasDeviceAnno.mmpk /sdcard/ArcGIS/Samples/MapPackage/GasDeviceAnno.mmpk`

Link | Local Location
---------|-------|
|[Gas device anno mobile map package](https://arcgisruntime.maps.arcgis.com/home/item.html?id=b87307dcfb26411eb2e92e1627cb615b)| `<sdcard>`/ArcGIS/Samples/MapPackage/GasDeviceAnno.mmpk|

## About the data

 The scale ranges were set by the map's author using ArcGIS Pro:
* The "Open" annotation sublayer has its maximum scale set to 1:500 and its minimum scale set to 1:2000.
* The "Closed" annotation sublayer has no minimum or maximum scales set, so will be drawn at all scales.

## Tags

annotation, scale, text, utilities, visualization
