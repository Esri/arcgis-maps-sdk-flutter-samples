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
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_info_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
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
  var _markdownHtml = '';
  Brightness? _lastBrightness;

  final _controller = WebViewController();

  @override
  void initState() {
    super.initState();

    _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);

          // Allow the view to load the initial 'about:blank' page.
          if (uri.scheme == 'about') {
            return NavigationDecision.navigate;
          }

          // Launch any other URL in the system browser (instead of this WebViewController).
          launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ),
    );

    _fetchMarkDown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // When the theme brightness changes, reload the HTML with the new theme colors.
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness == brightness) {
      return;
    }

    _lastBrightness = brightness;
    if (_markdownHtml.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _loadStyledHtml();
      }).ignore();
    }
  }

  Future<void> _fetchMarkDown() async {
    final readmeUrl =
        'https://raw.githubusercontent.com/Esri/arcgis-maps-sdk-flutter-samples/main/lib/samples/${widget.sample.key}/README.md';
    final imageUrl =
        'https://github.com/Esri/arcgis-maps-sdk-flutter-samples/raw/main/lib/samples/${widget.sample.key}/${widget.sample.key}.png';

    final response = await http.get(Uri.parse(readmeUrl));
    if (!mounted) return;

    if (response.statusCode == 200) {
      var markdownData = response.body;

      // Replace the image URL from Markdown.
      markdownData = markdownData.replaceAll(
        '${widget.sample.key}.png',
        imageUrl,
      );

      // Convert the markdown to html.
      _markdownHtml = md.markdownToHtml(markdownData);

      setState(() {
        _isLoading = false;
      });

      _loadStyledHtml();
    } else {
      setState(() {
        _markdownHtml = '<p>Failed to load README.md</p>';
        _isLoading = false;
      });

      _loadStyledHtml();
    }
  }

  void _loadStyledHtml() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final styledHtml =
        '''
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          :root {
            color-scheme: ${theme.brightness == Brightness.dark ? 'dark' : 'light'};
          }
          body {
            background-color: ${_toCssColor(colorScheme.surface)};
            color: ${_toCssColor(colorScheme.onSurface)};
            font-family: Arial, sans-serif;
            line-height: 1.6;
            padding: 16px;
            word-wrap: break-word;
            overflow-wrap: break-word;
          }
          a {
            color: ${_toCssColor(colorScheme.primary)};
          }
          h1, h2, h3, h4, h5, h6 {
            color: ${_toCssColor(colorScheme.onSurface)};
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
          }
          code {
            background-color: ${_toCssColor(colorScheme.surfaceContainer)};
            padding: 2px 4px;
            color: ${_toCssColor(colorScheme.onSurface)};
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
        $_markdownHtml
      </body>
      </html>
    ''';

    _htmlData = styledHtml;
    _controller.loadHtmlString(_htmlData);
  }

  String _toCssColor(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(widget.sample.title),
        ),
        actions: [SampleInfoPopupMenu(sample: widget.sample)],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorScheme.surfaceContainer,
            child: ListTile(
              leading: Icon(Icons.description, color: colorScheme.onSurface),
              title: Text(
                'Readme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
