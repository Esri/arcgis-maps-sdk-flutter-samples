//
// Copyright 2026 Esri
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

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListGeodatabaseVersions extends StatefulWidget {
  const ListGeodatabaseVersions({super.key});

  @override
  State<ListGeodatabaseVersions> createState() =>
      _ListGeodatabaseVersionsState();
}

class _ListGeodatabaseVersionsState extends State<ListGeodatabaseVersions>
    with SampleStateSupport {
  // A geoprocessing task to list geodatabase versions from a sample service.
  final _geoprocessingTask = GeoprocessingTask(
    uri: Uri.parse(
      'https://sampleserver6.arcgisonline.com/arcgis/rest/services/'
      'GDBVersions/GPServer/ListVersions',
    ),
  );

  // The geoprocessing job created to list versions. Stored here so it can be
  // cancelled if the widget is disposed.
  GeoprocessingJob? _job;
  var _isLoading = false;
  var _errorMessage = '';
  var _versions = <_GeodatabaseVersionInfo>[];

  @override
  void initState() {
    super.initState();
    _loadVersions().ignore();
  }

  @override
  void dispose() {
    _job?.cancel().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Geodatabase versions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadVersions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                Text(
                  'Connect to a geoprocessing service and list the returned '
                  'geodatabase versions.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _versions.isEmpty
                      ? 'No versions loaded.'
                      : '${_versions.length} versions found.',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_errorMessage.isNotEmpty) ...[
                  Text(
                    _errorMessage,
                    style: Theme.of(context).textTheme.customErrorStyle,
                  ),
                ],
                Expanded(child: _buildVersionList()),
              ],
            ),
            LoadingIndicator(visible: _isLoading, text: 'Listing versions...'),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionList() {
    if (_versions.isEmpty) {
      return ListView(
        children: const [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tap Refresh to run the geoprocessing task and view the '
                'versions returned by the service.',
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVersions,
      child: ListView.separated(
        itemCount: _versions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final version = _versions[index];
          return _VersionCard(version: version);
        },
      ),
    );
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create default parameters for the geoprocessing task.
      final parameters = await _geoprocessingTask.createDefaultParameters();

      // Create a job to execute the task with the parameters.
      final job = _geoprocessingTask.createJob(parameters: parameters);

      // Store the job so it can be cancelled if the widget is disposed before it completes.
      _job = job;

      // Run the job and wait for the result.
      final result = await job.run();
      // Get the "Versions" output from the result, which should be a feature set.
      final output = result.outputs['Versions'];
      if (output is! GeoprocessingFeatures) {
        throw StateError(
          'The geoprocessing result did not include a Versions feature set.',
        );
      }
      // Load the features from the output if they haven't been loaded already.
      if (output.features == null) {
        await output.fetchOutputFeatures();
      }

      final featureSet = output.features;
      if (featureSet == null) {
        throw StateError('The Versions output did not contain any features.');
      }

      // Convert the features to _GeodatabaseVersionInfo objects.
      final versions =
          featureSet
              .features()
              .map(
                (feature) =>
                    _GeodatabaseVersionInfo.fromAttributes(feature.attributes),
              )
              .whereType<_GeodatabaseVersionInfo>()
              .toList()
            ..sort((a, b) {
              final objectIdCompare = (a.objectId ?? 1 << 30).compareTo(
                b.objectId ?? 1 << 30,
              );
              return objectIdCompare != 0
                  ? objectIdCompare
                  : a.name.compareTo(b.name);
            });

      setState(() => _versions = versions);
    } on ArcGISException catch (e) {
      setState(() => _errorMessage = e.message);
    } on Exception catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      _job = null;
      setState(() => _isLoading = false);
    }
  }
}

// A card widget to display information about a geodatabase version.
class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.version});

  final _GeodatabaseVersionInfo version;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                version.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Object ID',
                value: version.objectId?.toString() ?? 'Unavailable',
              ),
              _InfoRow(label: 'Access', value: version.access),
              _InfoRow(label: 'Created', value: version.createdText),
              _InfoRow(label: 'Last modified', value: version.lastModifiedText),
              _InfoRow(label: 'Is owner', value: version.isOwnerText),
              _InfoRow(
                label: 'Parent version',
                value: version.parentVersionName,
              ),
              if (version.description.isNotEmpty)
                _InfoRow(label: 'Description', value: version.description),
            ],
          ),
        ),
      ),
    );
  }
}

// A widget to display a label and value in a consistent style, used to show
// information about a geodatabase version in the _VersionCard.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// A class to hold information about a geodatabase version,
// extracted from the attributes of a geoprocessing result feature.

class _GeodatabaseVersionInfo {
  _GeodatabaseVersionInfo({
    required this.name,
    required this.access,
    required this.created,
    required this.description,
    required this.isOwner,
    required this.lastModified,
    required this.objectId,
    required this.parentVersionName,
  });

  final String name;
  final String access;
  final DateTime? created;
  final String description;
  final String isOwner;
  final DateTime? lastModified;
  final int? objectId;
  final String parentVersionName;

  static final _dateFormatter = DateFormat.yMMMd().add_jm();

  String get createdText => _formatDate(created);

  String get isOwnerText => isOwner.isEmpty ? 'Unavailable' : isOwner;

  String get lastModifiedText => _formatDate(lastModified);

  static _GeodatabaseVersionInfo? fromAttributes(
    Map<String, Object?> attributes,
  ) {
    final name = _stringValue(attributes, 'name');
    if (name.isEmpty) {
      return null;
    }

    return _GeodatabaseVersionInfo(
      name: name,
      access: _stringValue(attributes, 'access', fallback: 'Unavailable'),
      created: _dateValue(attributes, 'created'),
      description: _stringValue(attributes, 'description'),
      isOwner: _stringValue(attributes, 'isowner', fallback: 'Unavailable'),
      lastModified: _dateValue(attributes, 'lastmodified'),
      objectId: _intValue(attributes, 'objectid'),
      parentVersionName: _stringValue(
        attributes,
        'parentversionname',
        fallback: 'Unavailable',
      ),
    );
  }

  static DateTime? _dateValue(Map<String, Object?> attributes, String key) {
    final value = _rawValue(attributes, key);
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static String _formatDate(DateTime? value) {
    return value == null ? 'Unavailable' : _dateFormatter.format(value);
  }

  static int? _intValue(Map<String, Object?> attributes, String key) {
    final value = _rawValue(attributes, key);
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static Object? _rawValue(Map<String, Object?> attributes, String key) {
    final normalizedKey = key.toLowerCase();
    for (final entry in attributes.entries) {
      if (entry.key.toLowerCase() == normalizedKey) {
        return entry.value;
      }
    }
    return null;
  }

  static String _stringValue(
    Map<String, Object?> attributes,
    String key, {
    String fallback = '',
  }) {
    final value = _rawValue(attributes, key);
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
