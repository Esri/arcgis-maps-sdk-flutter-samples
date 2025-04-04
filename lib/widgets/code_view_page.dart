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
  late final codeMap = _loadCodeMap(widget.sample.key);
  int selectedFileIndex = 0;

  @override
  Widget build(BuildContext context) {
    final filePath = codeMap.keys.elementAt(selectedFileIndex);
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
                builder: (
                  BuildContext context,
                  AsyncSnapshot<String> snapshot,
                ) {
                  if (snapshot.hasData) {
                    final codeString = snapshot.data!;
                    return SyntaxView(
                      code: codeString,
                      syntax: Syntax.DART,
                      syntaxTheme: SyntaxTheme.vscodeLight(),
                    );
                  } else if (snapshot.hasError) {
                    final exception = snapshot.error! as CodeViewExeption;
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
                        selectedFileIndex > 0
                            ? () {
                              setState(() => selectedFileIndex -= 1);
                            }
                            : null,
                    child: const Text('Prev.'),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedFileIndex < codeMap.length - 1
                            ? () {
                              setState(() => selectedFileIndex += 1);
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
        'https://raw.githubusercontent.com/Esri/arcgis-maps-sdk-flutter-samples/refs/heads/v.next/lib/samples/';
    final fileUrl = '$urlPrefix/$filePath';
    final fileUri = Uri.parse(fileUrl);
    final response = await http.get(fileUri);
    if (response.statusCode != 200) {
      throw CodeViewExeption(
        url: fileUrl,
        message:
            'HTTP request failed with status: ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    return response.body;
  }
}

class CodeViewExeption implements Exception {
  CodeViewExeption({required this.url, this.message});

  final String? message;
  final String url;
}
