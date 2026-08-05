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

import 'package:arcgis_maps_sdk_flutter_samples/common/api_key_manager.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutInfo extends StatefulWidget {
  const AboutInfo({required this.title, super.key});

  final String title;

  @override
  State<AboutInfo> createState() => _AboutInfoState();
}

class _AboutInfoState extends State<AboutInfo> {
  // Package metadata shown in the About sheet.
  final _packageInfoFuture = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: .bold)),
        Row(
          mainAxisAlignment: .spaceEvenly,
          children: [
            Text(
              'Version',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: .bold,
              ),
            ),
            FutureBuilder(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == .done) {
                  return Text(
                    '${snapshot.data?.version}.${snapshot.data?.buildNumber}',
                  );
                }

                return const Text('');
              },
            ),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: ApiKeyManager.isUsingOverride,
          builder: (context, isUsingOverride, child) {
            return ListTile(
              contentPadding: .zero,
              leading: const Icon(Icons.key),
              title: const Text('API key'),
              subtitle: Text(
                isUsingOverride ? 'Custom key set' : 'Build-time key',
              ),
              trailing: FilledButton(
                onPressed: () => _showApiKeyDialog(context, isUsingOverride),
                child: const Text('Set'),
              ),
            );
          },
        ),
      ],
    );
  }

  // Shows the API key override dialog and reports the result.
  Future<void> _showApiKeyDialog(
    BuildContext context,
    bool isUsingOverride,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<_ApiKeyDialogResult>(
      context: context,
      builder: (context) => _ApiKeyDialog(isUsingOverride: isUsingOverride),
    );

    if (!context.mounted) return;

    switch (result) {
      case _ApiKeyDialogResult.overrideApplied:
        messenger.showSnackBar(
          const SnackBar(content: Text('API key override applied.')),
        );
      case _ApiKeyDialogResult.buildTimeKeyApplied:
        messenger.showSnackBar(
          const SnackBar(content: Text('Using build-time API key.')),
        );
      case null:
        break;
    }
  }
}

// The action completed from the API key dialog.
enum _ApiKeyDialogResult { overrideApplied, buildTimeKeyApplied }

// Dialog for setting or clearing the session-only API key override.
class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.isUsingOverride});

  // Whether a session-only API key override is currently active.
  final bool isUsingOverride;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  // Holds new key input without pre-filling or revealing the active key.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set API key'),
      content: TextField(
        controller: _controller,
        // Always start empty and obscure input so the active key is never shown.
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'API key',
          hintText: 'Enter API key',
        ),
      ),
      actions: [
        if (widget.isUsingOverride)
          TextButton(
            onPressed: () {
              ApiKeyManager.applyBuildTimeApiKey();
              Navigator.pop(context, _ApiKeyDialogResult.buildTimeKeyApplied);
            },
            child: const Text('Use build-time key'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!ApiKeyManager.applyOverride(_controller.text)) return;

            Navigator.pop(context, _ApiKeyDialogResult.overrideApplied);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}
