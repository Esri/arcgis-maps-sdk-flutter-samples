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
  // The portal to search for web maps.
  final _portal = Portal.arcGISOnline();

  // The current set of search results.
  final _portalItems = <PortalItem>[];

  // The query parameters for the next page of results.
  PortalQueryParameters? _nextQueryParameters;

  // The current search version, used to discard outdated search results.
  var _searchVersion = 0;

  // Whether results are currently being loaded.
  var _isLoadingMore = false;

  // The controller for the search field.
  final _searchController = TextEditingController();

  // The controller for the scroll area of results, used to detect when the user scrolls near the end.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Watch the list position so the next page can load when the list is scrolled near the end.
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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              // A search field for entering queries.
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
            // An indicator that results are being loaded.
            if (_isLoadingMore) const LinearProgressIndicator(),
            // The list of search results.
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    // Show an empty state before a search begins.
    if (_searchController.text.trim().isEmpty) {
      return const Center(child: Text('Search ArcGIS Online for web maps.'));
    }

    // Show a message when the query returns no portal items.
    if (!_isLoadingMore && _portalItems.isEmpty) {
      return const Center(child: Text('No results.'));
    }

    // Build a list of search results.
    return ListView.separated(
      // The scroll controller is used to detect when the user scrolls near the end of the list.
      controller: _scrollController,
      itemCount: _portalItems.length,
      itemBuilder: (context, index) =>
          _buildPortalItemRow(context, _portalItems[index]),
      separatorBuilder: (_, _) => const Divider(),
    );
  }

  Widget _buildPortalItemRow(BuildContext context, PortalItem item) {
    final thumbnailUri = item.thumbnail?.uri;

    // Present the thumbnail, title, update date, and item owner of a single item.
    return ListTile(
      // The item thumbnail (if available).
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
      // The item title.
      title: Text(item.title, maxLines: 2, overflow: .ellipsis),
      // The last-modified date and owner.
      subtitle: Text(
        '${item.modified?.toString().split(' ').first ?? ''} | ${item.owner}',
        maxLines: 1,
        overflow: .ellipsis,
      ),
      // When the user taps the item, load the web map in a new page.
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

    // Return if there is no query.
    if (_nextQueryParameters == null) return;

    setState(() => _isLoadingMore = true);
    final requestVersion = _searchVersion;
    try {
      // Run the query to find matching items in the portal.
      final resultSet = await _portal.findItems(
        parameters: _nextQueryParameters!,
      );
      if (!mounted || requestVersion != _searchVersion) return;

      // Update the UI with the new search results.
      setState(() {
        _portalItems.addAll(resultSet.results);
        _nextQueryParameters = resultSet.nextQueryParameters;
        _isLoadingMore = false;
      });
    } on Exception catch (error) {
      if (!mounted || requestVersion != _searchVersion) return;

      // An error occurred while performing the search.
      setState(() => _isLoadingMore = false);
      showExceptionDialog('Error searching for web maps', error);
    }
  }

  void _loadNextPageWhenNearEnd() {
    // Check if more results should be loaded based on the scroll position.
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        _nextQueryParameters == null) {
      return;
    }

    // Fetch another page when the user scrolls close to the bottom of the list.
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
      // Show the item title in the app bar.
      appBar: AppBar(title: Text(item.title)),
      // Load the web map from the selected portal item.
      body: ArcGISMapView(
        controllerProvider: () =>
            ArcGISMapView.createController()
              ..arcGISMap = ArcGISMap.withItem(item),
      ),
    );
  }
}
