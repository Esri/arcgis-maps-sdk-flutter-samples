//
// Copyright 2025 Esri
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

import 'dart:async';
import 'dart:typed_data';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// A widget that creates and displays a swatch image for a symbol.
class SwatchImage extends StatefulWidget {
  const SwatchImage({
    required this.symbol,
    this.width = 10,
    this.height = 10,
    super.key,
  });

  final ArcGISSymbol symbol;
  final double width;
  final double height;

  @override
  State<SwatchImage> createState() => _SwatchImageState();
}

class _SwatchImageState extends State<SwatchImage> {
  // A Completer that completes when the swatch image is ready.
  final _swatchCompleter = Completer<Uint8List>();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // Get the device pixel ratio after the first frame to ensure it is accurate.
      final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

      // Create a swatch image from the symbol.
      widget.symbol
          .createSwatch(
            screenScale: devicePixelRatio,
            width: widget.width,
            height: widget.height,
          )
          .then((image) {
            // Signal that the swatch image is ready.
            _swatchCompleter.complete(image.getEncodedBuffer());
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _swatchCompleter.future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // The swatch image is ready -- display it.
          return Image.memory(snapshot.data!);
        }

        // Until the image is ready, reserve space to avoid layout changes.
        return SizedBox(width: widget.width, height: widget.height);
      },
    );
  }
}
