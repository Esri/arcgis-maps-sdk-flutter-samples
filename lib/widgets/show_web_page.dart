import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShowWebPage extends StatefulWidget {
  const ShowWebPage({required this.sample, super.key});

  final Sample sample;

  @override
  State<ShowWebPage> createState() => _ShowWebPageState();
}

class _ShowWebPageState extends State<ShowWebPage> {
  late WebViewController _controller;

  String webPageUrl() {
    final formattedKey = widget.sample.key.replaceAll('_', '-');
    final formattedUrl =
        'https://developers.arcgis.com/flutter/sample-code/$formattedKey/';

    return formattedUrl;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(webPageUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sample.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
