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

import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:flutter/material.dart';
import 'package:flutter_syntax_view/flutter_syntax_view.dart';
import 'package:http/http.dart' as http;

class CodeViewPage extends StatefulWidget {
  const CodeViewPage({required this.sample, super.key});
  final Sample sample;

  @override
  State<StatefulWidget> createState() => _CodeViewPageState();
}

class _CodeViewPageState extends State<CodeViewPage> {
  var _selectedFileIndex = 0;
  late final codeMap = _loadCodeMap(widget.sample.key);

  @override
  Widget build(BuildContext context) {
    final filePath = codeMap.keys.elementAt(_selectedFileIndex);
    final fileName = filePath.split('/').last;

    return Scaffold(
      appBar: AppBar(title: Text(widget.sample.title)),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          children: [
            Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder(
                future: codeMap[filePath],
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final codeString = snapshot.data!;
                    return SyntaxView(
                      code: codeString,
                      syntax: Syntax.DART,
                      syntaxTheme: SyntaxTheme.vscodeLight(),
                    );
                  } else if (snapshot.hasError) {
                    final exception = snapshot.error! as CodeViewException;
                    return Center(
                      child: Text(
                        'Could not load code with error: ${exception.message}',
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            Visibility(
              visible: codeMap.length > 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed:
                        _selectedFileIndex > 0
                            ? () {
                              setState(() => _selectedFileIndex -= 1);
                            }
                            : null,
                    child: const Text('Prev.'),
                  ),
                  ElevatedButton(
                    onPressed:
                        _selectedFileIndex < codeMap.length - 1
                            ? () {
                              setState(() => _selectedFileIndex += 1);
                            }
                            : null,
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Future<String>> _loadCodeMap(String sampleName) {
    final codeMap = <String, Future<String>>{};
    for (final filename in widget.sample.snippets) {
      codeMap[filename] = _fetchOnlineCodeForFile('$sampleName/$filename');
    }

    return codeMap;
  }

  Future<String> _fetchOnlineCodeForFile(String filePath) async {
    const urlPrefix =
        'https://raw.githubusercontent.com/Esri/arcgis-maps-sdk-flutter-samples/refs/heads/main/lib/samples/';
    final fileUrl = '$urlPrefix/$filePath';
    final fileUri = Uri.parse(fileUrl);
    final response = await http.get(fileUri);
    if (response.statusCode != 200) {
      throw CodeViewException(
        url: fileUrl,
        message:
            'HTTP request failed with status: ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    return response.body;
  }
}

class CodeViewException implements Exception {
  CodeViewException({required this.url, this.message});

  final String? message;
  final String url;
}
