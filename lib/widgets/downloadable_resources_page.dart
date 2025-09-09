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
import 'dart:io';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/download_util.dart';
import 'package:arcgis_maps_sdk_flutter_samples/models/downloadable_resource.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

typedef OnComplete = void Function(List<String>);

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
  var _isCancelled = false;
  var _progress = 0.0;
  
  // To manage cancellation of download
  CancelableOperation<List<ResponseInfo>>? _cancelableDownload;

  @override
  void initState() {
    super.initState();
    _checkIfResourcesExist();
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This sample requires downloadable resources',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${(_progress * 100).toInt()}% download complete',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
      ),
    );
  }

  // Check if all resources already exist.
  Future<void> _checkIfResourcesExist() async {
    final appDir = await getApplicationDocumentsDirectory();
    var allResourcesExist = true;

    for (final resource in widget.resources) {
      final file = File(path.join(appDir.absolute.path, resource.downloadable));
      if (!file.existsSync()) {
        allResourcesExist = false;
        break;
      }
    }

    if (allResourcesExist) {
      setState(() {
        _isComplete = true;
        _progress = 1.0;
      });
    }
  }

  // Start the download of resources.
  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _isCancelled = false;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final itemIds = widget.resources.map((r) => r.itemId).toList();
      final destinationFiles = widget.resources.map((r) {
        return File(path.join(appDir.absolute.path, r.downloadable));
      }).toList();

      _cancelableDownload = CancelableOperation.fromFuture(
        // Start the download process
        downloadSampleDataWithProgress(
          itemIds: itemIds,
          destinationFiles: destinationFiles,
          onProgress: (progress) {
            if (!_isCancelled) {
              setState(() {
                if (_isDownloading) {
                  _progress = progress >= 1.0 ? 1.0 : progress;
                }
              });
            }
          },
        ),
        // Handle cancellation
        onCancel: () async {
          await _cleanupFiles();

          setState(() {
            _isCancelled = true;
            _isDownloading = false;
            _isComplete = false;
            _progress = 0;
          });
        },
      );

      // Await the download result.
      final result = await _cancelableDownload!.value;
      if (result.isNotEmpty && !_isCancelled) {
        setState(() {
          _isComplete = true;
          _isDownloading = false;
          _progress = 1.0;
        });
      }
    } on Exception catch (_) {
      // Handle download error
      setState(() {
        _isDownloading = false;
        _isComplete = false;
        _progress = 0;
      });

      // show a snackbar with error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error downloading resources. Please try again.'),
          ),
        );
      }
    }
  }

  // Get the file paths of the downloaded resources.
  Future<List<String>> _getDownloadFilePaths() async {
    final appDir = await getApplicationDocumentsDirectory();
    return widget.resources.map((res) {
      final downloadablePrefix = res.downloadable.split('.').first;
      if (res.downloadable.toLowerCase().endsWith('.zip')) {
        return res.resource != null
            ? path.join(appDir.absolute.path, downloadablePrefix, res.resource!)
            : path.join(appDir.absolute.path, downloadablePrefix);
      } else {
        return path.join(appDir.absolute.path, res.downloadable);
      }
    }).toList();
  }

  // Clean up partially downloaded files.
  Future<void> _cleanupFiles() async {
    final appDir = await getApplicationDocumentsDirectory();
    for (final resource in widget.resources) {
      final file = File(path.join(appDir.absolute.path, resource.downloadable));
      if (file.existsSync()) {
        file.deleteSync();
      }
      final dir = Directory(
        path.join(appDir.absolute.path, resource.downloadable.split('.').first),
      );
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }

  // Cancel the ongoing download.
  Future<void> _cancelDownload() async {
    await _cancelableDownload?.cancel();
    _cancelableDownload = null;
  }

  // Call back to onComplete.
  Future<void> _openSample() async {
    final downloadPaths = await _getDownloadFilePaths();
    widget.onComplete(downloadPaths);
  }
}
