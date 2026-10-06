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
import 'package:material_ui/material_ui.dart';

class SearchForWebMap extends StatefulWidget {
  const SearchForWebMap({super.key});

  @override
  State<SearchForWebMap> createState() => _SearchForWebMapState();
}

class _SearchForWebMapState extends State<SearchForWebMap>
    with SampleStateSupport {
  final _portal = Portal.arcGISOnline();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _portalItems = <PortalItem>[];
  PortalQueryParameters? _nextQueryParameters;
  var _searchVersion = 0;
  var _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    // Watch the list position so the next page can load as needed.
    _scrollController.addListener(_loadNextPageWhenNearEnd);
  }

  @override
  void dispose() {
    // Release the controllers.
    _searchController.dispose();
    _scrollController
      ..removeListener(_loadNextPageWhenNearEnd)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build the search field and the portal result list.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                textInputAction: .search,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Search web maps...',
                  suffixIcon: _searchController.text.isEmpty
                      ? const Icon(Icons.search)
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _search('').ignore();
                          },
                          icon: const Icon(Icons.cancel),
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _search,
              ),
            ),
            if (_isLoadingMore) const LinearProgressIndicator(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    // Show a useful empty state before a search begins.
    if (_searchController.text.trim().isEmpty) {
      return const Center(child: Text('Search ArcGIS Online for web maps.'));
    }

    // Explain when the current query returns no portal items.
    if (!_isLoadingMore && _portalItems.isEmpty) {
      return const Center(child: Text('No results.'));
    }

    // Build rows and load another page as the list approaches its end.
    return ListView.separated(
      controller: _scrollController,
      itemCount: _portalItems.length,
      itemBuilder: (context, index) =>
          _buildPortalItemRow(context, _portalItems[index]),
      separatorBuilder: (_, _) => const Divider(),
    );
  }

  Widget _buildPortalItemRow(BuildContext context, PortalItem item) {
    // Present the thumbnail, title, update date, and item owner together.
    final thumbnailUri = item.thumbnail?.uri;

    return ListTile(
      leading: SizedBox(
        width: 80,
        height: 60,
        child: thumbnailUri == null
            ? const Icon(Icons.map_outlined)
            : Image.network(
                thumbnailUri.toString(),
                fit: .cover,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
              ),
      ),
      title: Text(item.title, maxLines: 2, overflow: .ellipsis),
      subtitle: Text(
        '${item.modified?.toString().split(' ').first ?? ''} | ${item.owner}',
        maxLines: 1,
        overflow: .ellipsis,
      ),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => _WebMapPage(item: item))),
    );
  }

  Future<void> _search(String query) async {
    // Invalidate older requests.
    ++_searchVersion;

    // Clear the current search state.
    setState(() {
      _portalItems.clear();
      _nextQueryParameters = null;
      _isLoadingMore = false;
    });

    // Prepare the initial query parameters.
    final searchString = query.trim();
    if (searchString.isEmpty) return;
    _nextQueryParameters = PortalQueryParameters.forItems(
      types: const [.webMap],
      searchString: searchString,
    );

    // Load the first page.
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    // Return if a page is already being loaded.
    if (_isLoadingMore) return;

    if (_nextQueryParameters == null) return;

    setState(() => _isLoadingMore = true);

    final requestVersion = _searchVersion;
    try {
      final resultSet = await _portal.findItems(
        parameters: _nextQueryParameters!,
      );
      if (!mounted || requestVersion != _searchVersion) return;

      setState(() {
        _portalItems.addAll(resultSet.results);
        _nextQueryParameters = resultSet.nextQueryParameters;
        _isLoadingMore = false;
      });
    } on Exception catch (error) {
      if (!mounted || requestVersion != _searchVersion) return;

      setState(() => _isLoadingMore = false);
      showExceptionDialog('Error searching for web maps', error);
    }
  }

  void _loadNextPageWhenNearEnd() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        _nextQueryParameters == null) {
      return;
    }

    // Fetch another page when the user scrolls close to the final result.
    if (_scrollController.position.extentAfter < 300) {
      _loadNextPage().ignore();
    }
  }
}

// A page to display the web map from the selected portal item.
class _WebMapPage extends StatelessWidget {
  const _WebMapPage({required this.item});

  final PortalItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ArcGISMapView(
        controllerProvider: () =>
            ArcGISMapView.createController()
              ..arcGISMap = ArcGISMap.withItem(item),
      ),
    );
  }
}
