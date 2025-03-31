import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;

class ReadmePage extends StatefulWidget {
  const ReadmePage({required this.sample, super.key});

  final Sample sample;

  @override
  State<ReadmePage> createState() => _ReadmePageState();
}

class _ReadmePageState extends State<ReadmePage> {
  var _htmlData = '';
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarkDown();
  }

  Future<void> _fetchMarkDown() async {
    final readmeUrl = formatUrls()[0];
    final imageUrl = formatUrls()[1];

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

      setState(() {
        _htmlData = html;
        _isLoading = false;
      });
    } else {
      setState(() {
        _htmlData = 'Failed to load README.md';
        _isLoading = false;
      });
    }
  }

  List<String> formatUrls() {
    final keyUrls = <String>[];
    final readmeUrl =
        'https://raw.githubusercontent.com/Esri/arcgis-maps-sdk-flutter-samples/v.next/lib/samples/${widget.sample.key}/README.md';
    final imageUrl =
        'https://github.com/Esri/arcgis-maps-sdk-flutter-samples/raw/v.next/lib/samples/${widget.sample.key}/${widget.sample.key}.png';

    keyUrls.add(readmeUrl);
    keyUrls.add(imageUrl);

    return keyUrls;
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
            child:  const ListTile(
              leading: Icon(Icons.description),
              title: Text(
                'Readme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Html(data: _htmlData),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
