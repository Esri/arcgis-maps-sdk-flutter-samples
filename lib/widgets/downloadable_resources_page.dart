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

import 'dart:async';
import 'dart:io';
import 'package:arcgis_maps_sdk_flutter_samples/common/sample_data.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/downloadable_resource.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

typedef OnComplete = void Function(Object);

/// A page that handles downloading resources required by a sample before opening it.
///
/// This page follows the workflow:
/// - Display sample name and downloadable resources requirement
/// - Allow user to start/cancel download
/// - Show progress during download
/// - Navigate to sample once download is complete
class DownloadableResourcesPage extends StatefulWidget {
  const DownloadableResourcesPage({
    required this.sampleTitle,
    required this.resources,
    required this.onComplete,
    super.key,
  });

  final String sampleTitle;
  final List<DownloadableResource> resources;
  final OnComplete onComplete;

  @override
  State<DownloadableResourcesPage> createState() =>
      _DownloadableResourcesPageState();
}

class _DownloadableResourcesPageState extends State<DownloadableResourcesPage> {
  var _isDownloading = false;
  var _isComplete = false;
  var _progress = 0.0;
  StreamSubscription<double>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _checkIfResourcesExist();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkIfResourcesExist() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      bool allResourcesExist = true;

      for (final resource in widget.resources) {
        final file = File(
          '${appDir.absolute.path}/${resource.fileName.split('.').first}',
        );
        if (!file.existsSync()) {
          allResourcesExist = false;
          break;
        }
      }

      if (allResourcesExist) {
        setState(() {
          _isComplete = true;
        });
      }
    } catch (e) {
      // If checking fails, assume resources need to be downloaded
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final itemIds = widget.resources.map((r) => r.itemId).toList();
      final destinationFiles = widget.resources.map((r) {
        return File('${appDir.absolute.path}/${r.fileName}');
      }).toList();

      await downloadSampleDataWithProgress(
        itemIds: itemIds,
        destinationFiles: destinationFiles,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _isComplete = true;
        _isDownloading = false;
      });
    } on Exception catch (e) {
      // Handle download error
      setState(() {
        _isDownloading = false;
        _progress = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<List<String>> _getDownloadFilePaths() async {
    final appDir = await getApplicationDocumentsDirectory();
    return widget.resources
        .map(
          (r) =>
              '${appDir.absolute.path}/${r.fileName.split('.').first}/${r.fileName.split('.').first}',
        )
        .toList();
  }

  Future<void> _cancelDownload() async {
    await _progressSubscription?.cancel();

    // Clean up any partial files
    try {
      final appDir = await getApplicationDocumentsDirectory();
      for (final resource in widget.resources) {
        final file = File(
          '${appDir.absolute.path}/${resource.fileName.split('.').first}',
        );
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    } on Exception catch (_) {
      // Ignore cleanup errors
    }

    setState(() {
      _isDownloading = false;
      _progress = 0;
    });
  }

  void _openSample() async {
    final downloadPaths = await _getDownloadFilePaths();
    print(downloadPaths);
    // GoRouter.of(
    //   context,
    // ).go('/sample/${widget.sampleTitle}/live', extra: downloadPaths);
    widget.onComplete(downloadPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sampleTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isDownloading) {
              unawaited(_cancelDownload());
            }
            context.pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          spacing: 20,
          children: [
            Text(
              'This sample requires downloadable resources:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(value: _progress),
            ),

            Text(
              '${(_progress * 100).toInt()}% download complete',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            ElevatedButton(
              onPressed: _isDownloading
                  ? _cancelDownload
                  : _isComplete
                  ? _openSample
                  : _startDownload,
              child: Text(
                _isDownloading
                    ? 'Cancel'
                    : _isComplete
                    ? 'Open'
                    : 'Download',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
