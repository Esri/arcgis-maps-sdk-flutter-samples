//
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
import 'package:flutter/material.dart';

class ManageBookmarksSample extends StatefulWidget {
  const ManageBookmarksSample({super.key});

  @override
  State<ManageBookmarksSample> createState() => _ManageBookmarksSampleState();
}

class _ManageBookmarksSampleState extends State<ManageBookmarksSample> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  late final List<Bookmark> _bookmarks;
  // A flag for when the map view is ready and controls can be used.
  var _ready = false;
  // A flag for when the bookmarks bottom sheet is visible.
  var _bookmarksVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // A button to add a bookmark at the current Viewpoint.
                    ElevatedButton(
                      onPressed: addBookmark,
                      child: const Text('Add Bookmark'),
                    ),
                    // A button to list the bookmarks.
                    ElevatedButton(
                      onPressed: () => setState(() => _bookmarksVisible = true),
                      child: const Text('Bookmarks'),
                    ),
                  ],
                ),
              ],
            ),
            // Display a progress indicator and prevent interaction until state is ready.
            Visibility(
              visible: !_ready,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.white30,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
      // The Bookmarks bottom sheet.
      bottomSheet: _bookmarksVisible ? buildBookmarks(context) : null,
    );
  }

  // The build method for the Bookmarks bottom sheet.
  Widget buildBookmarks(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20.0,
        0.0,
        20.0,
        max(
          20.0,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      //fixme scrollview?
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Bookmarks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _bookmarksVisible = false),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              return TextButton(
                onPressed: () =>
                    _mapViewController.setBookmark(_bookmarks[index]),
                style: const ButtonStyle(
                  alignment: Alignment.centerLeft,
                ),
                child: Text(_bookmarks[index].name),
              );
            },
          ),
        ],
      ),
    );
  }

  void onMapViewReady() {
    //fixme comments
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);

    _bookmarks = map.bookmarks;

    _bookmarks.addAll([
      Bookmark(
        name: 'Grand Prismatic Spring',
        viewpoint: Viewpoint.withLatLongScale(
            latitude: 44.525, longitude: -110.838, scale: 6e3),
      ),
      Bookmark(
        name: 'Guitar-Shaped Forest',
        viewpoint: Viewpoint.withLatLongScale(
            latitude: -33.867, longitude: -63.985, scale: 4e4),
      ),
      Bookmark(
        name: 'Mysterious Desert Pattern',
        viewpoint: Viewpoint.withLatLongScale(
            latitude: 27.380, longitude: 33.632, scale: 6e3),
      ),
      Bookmark(
        name: 'Strange Symbol',
        viewpoint: Viewpoint.withLatLongScale(
            latitude: 37.401, longitude: -116.867, scale: 6e3),
      ),
    ]);

    _mapViewController.arcGISMap = map;

    _mapViewController.setBookmark(_bookmarks.first);

    // Set the ready state variable to true to enable the sample UI.
    setState(() => _ready = true);
  }

  void addBookmark() async {
    //fixme
    setState(() => _ready = false);
    // Perform some task.
    print('Perform task');
    await Future.delayed(const Duration(seconds: 5));
    setState(() => _ready = true);
  }
}
