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
  var _progress = 0;
  var _shouldShowUI = true;

  // To manage cancellation of download
  final _requestCancelToken = RequestCancelToken();

  @override
  void initState() {
    super.initState();
    _checkIfResourcesExist();
  }

  @override
  Widget build(BuildContext context) {
    // Skip building the UI if resources already exist and we're about to navigate
    if (!_shouldShowUI) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sampleTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isDownloading) {
              _cancelDownload();
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
              // Download progress indicator
              Visibility(
                visible: _isDownloading,
                child: Column(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: _progress / 100.0,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_progress% download complete',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _isComplete,
                child: Text(
                  'The resources have been downloaded.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              // Button [Download|Cancel|Open]
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isDownloading
                    ? _cancelDownload
                    : _isComplete
                    ? _openSample
                    : _startDownload,
                child: Text(_isDownloading ? 'Cancel' : 'Download'),
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
        _progress = 100;
        _shouldShowUI = false;
      });

      // if the data has been downloaded, directly open the sample.
      if (mounted) {
        unawaited(_openSample());
      }
    }
  }

  // Start the download of resources.
  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final itemIds = widget.resources.map((r) => r.itemId).toList();
      final destinationFiles = widget.resources.map((r) {
        return File(path.join(appDir.absolute.path, r.downloadable));
      }).toList();

      await downloadSampleDataWithProgress(
        itemIds: itemIds,
        destinationFiles: destinationFiles,
        requestCancelToken: _requestCancelToken,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      setState(() {
        _isComplete = true;
        _isDownloading = false;
      });

      // directly open the sample after downloading
      unawaited(_openSample());
    } on Exception catch (e) {
      // show a snackbar with error message
      if (mounted) {
        var message = 'Error downloading resources. Please try again.';
        if (e is ArcGISException &&
            e.errorType == ArcGISExceptionType.commonUserDefinedFailure &&
            (e.wrappedException is ArcGISException?) &&
            (e.wrappedException as ArcGISException?)?.errorType ==
                ArcGISExceptionType.commonUserCanceled) {
          message = 'Cancelled';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }

      await _cleanupFiles();

      setState(() {
        _isDownloading = false;
        _isComplete = false;
        _progress = 0;
      });
    }
  }

  // Get the file paths of the downloaded resources.
  Future<List<String>> _getDownloadFilePaths() async {
    final appDir = await getApplicationDocumentsDirectory();
    return widget.resources.map((res) {
      final downloadablePrefix = res.downloadable.split('.').first;
      if (res.downloadable.toLowerCase().endsWith('.zip')) {
        return res.resource != null
            ? path.join(appDir.absolute.path, downloadablePrefix, res.resource)
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
  void _cancelDownload() {
    _requestCancelToken.cancel();
  }

  // Call back to onComplete.
  Future<void> _openSample() async {
    final downloadPaths = await _getDownloadFilePaths();
    widget.onComplete(downloadPaths);
  }
}
