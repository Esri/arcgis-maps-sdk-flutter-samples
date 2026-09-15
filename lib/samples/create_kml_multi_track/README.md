# Create KML multi-track

Create, save and preview a KML multi-track, captured from a location data source.

![Create KML multi-track](create_kml_multi_track.png)

## Use case

When capturing location data for outdoor activities such as hiking or skiing, it can be useful to record and share your path. This sample demonstrates how you can collect individual KML tracks during a navigation session, then combine and export them as a KML multi-track.

## How to use the sample

Tap **Record Track** to start recording your current path on the simulated trail. Tap **Stop Recording** to end recording and capture a KML track. Repeat these steps to capture multiple KML tracks in a single session. Tap the **Save** button to convert the recorded tracks into a KML multi-track and save it to a local `.kmz` file. Then use the picker to select a track from the saved KML multi-track. Tap the **Delete** button to remove the local file and reset the sample.

## How it works

1. Create an `ArcGISMap` with a basemap and a `GraphicsOverlay` to display the path geometry for your navigation route.
2. Create a `SimulatedLocationDataSource` to drive the `LocationDisplay`.
3. As you receive `Location` updates, add each point to a list of `KmlTrackElement` objects while recording.
4. Once recording stops, create a `KmlTrack` using one or more `KmlTrackElement` objects.
5. Combine one or more `KmlTrack` objects into a `KmlMultiTrack`.
6. Save the `KmlMultiTrack` inside a `KmlDocument`, then export the document to a `.kmz` file.
7. Load the saved `.kmz` file into a `KmlDataset` and locate the `KmlDocument` in the dataset's `rootNodes`. From the document's `childNodes` get the `KmlPlacemark` and retrieve the `KmlMultiTrack` geometry.
8. Retrieve the geometry of each track in the `KmlMultiTrack` by iterating through the list of tracks and obtaining the respective `KmlTrack.geometry`.

## Relevant API

* KmlDataset
* KmlDocument
* KmlMultiTrack
* KmlPlacemark
* KmlTrack
* LocationDisplay
* SimulatedLocationDataSource

## Tags

export, hiking, kml, kmz, multi-track, record, track
