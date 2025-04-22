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

import 'package:arcgis_maps_sdk_flutter_samples/models/sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_detail_page.dart';
import 'package:arcgis_maps_sdk_flutter_samples/widgets/sample_info_popup_menu.dart';
import 'package:flutter/material.dart';

class SampleListView extends StatefulWidget {
  const SampleListView({required this.samples, super.key});

  final List<Sample> samples;

  @override
  State<SampleListView> createState() => _SampleListViewState();
}

class _SampleListViewState extends State<SampleListView> {
  final _scrollController = ScrollController();
  final _itemsPerPage = 20;
  final _displayedSamples = <Sample>[];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadMoreItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    setState(() {
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      if (startIndex < widget.samples.length) {
        _displayedSamples.addAll(
          widget.samples.sublist(
            startIndex,
            endIndex > widget.samples.length ? widget.samples.length : endIndex,
          ),
        );
        _currentPage++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _displayedSamples.length,
      itemBuilder: (context, index) {
        final sample = _displayedSamples[index];
        return Card(
          child: ListTile(
            title: Text(sample.title),
            subtitle: Text(sample.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SampleDetailPage(sample: sample),
                ),
              );
            },
            contentPadding: const EdgeInsets.only(left: 20),
            trailing: SampleInfoPopupMenu(sample: sample),
          ),
        );
      },
    );
  }
}
