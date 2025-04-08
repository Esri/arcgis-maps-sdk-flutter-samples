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
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:webview_flutter/webview_flutter.dart';

class ReadmePage extends StatefulWidget {
  const ReadmePage({required this.sample, super.key});

  final Sample sample;

  @override
  State<ReadmePage> createState() => _ReadmePageState();
}

class _ReadmePageState extends State<ReadmePage> {
  var _isLoading = true;
  var _htmlData = '';

  final _controller = WebViewController();

  @override
  void initState() {
    super.initState();
    _fetchMarkDown();
  }

  Future<void> _fetchMarkDown() async {
    final readmeUrl =
        'https://raw.githubusercontent.com/Esri/arcgis-maps-sdk-flutter-samples/main/lib/samples/${widget.sample.key}/README.md';
    final imageUrl =
        'https://github.com/Esri/arcgis-maps-sdk-flutter-samples/raw/main/lib/samples/${widget.sample.key}/${widget.sample.key}.png';

    final response = await http.get(Uri.parse(readmeUrl));
    if (response.statusCode == 200) {
      var markdownData = response.body;

      // Replace the image URL from Markdown.
      markdownData = markdownData.replaceAll(
        '${widget.sample.key}.png',
        imageUrl,
      );

      // Convert the markdown to html.
      final html = md.markdownToHtml(markdownData);

      // Inject custom CSS for styling.
      final styledHtml = '''
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            padding: 16px;
            word-wrap: break-word;
            overflow-wrap: break-word;
          }
          h1, h2, h3, h4, h5, h6 {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
          }
          code {
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 4px;
            font-family: 'Courier New', Courier, monospace;
          }
          img {
            max-width: 100%;
            height: auto;
          }
        </style>
      </head>
      <body>
        $html
      </body>
      </html>
    ''';

      setState(() {
        _htmlData = styledHtml;
        _controller.loadHtmlString(_htmlData);
        _isLoading = false;
      });
    } else {
      setState(() {
        _htmlData = 'Failed to load README.md';
        _controller.loadHtmlString(_htmlData);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sample.title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[300],
            child: const ListTile(
              leading: Icon(Icons.description),
              title: Text(
                'Readme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
