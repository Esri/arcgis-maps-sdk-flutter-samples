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
  final List<PortalItem> _portalItems = [];
  PortalQueryParameters? _nextQueryParameters;
  var _searchVersion = 0;
  var _isSearching = false;
  var _isLoadingMore = false;
  Object? _searchError;

  @override
  void initState() {
    // Watch the list position so the next page can load as needed.
    super.initState();
    _scrollController.addListener(_loadNextPageWhenNearEnd);
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Search web maps',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _search('').ignore();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _search,
                onSubmitted: _search,
              ),
            ),
            if (_isSearching) const LinearProgressIndicator(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    // Show a useful empty state before a search begins.
    if (_searchController.text.trim().isEmpty && _portalItems.isEmpty) {
      return const Center(child: Text('Search ArcGIS Online for web maps.'));
    }

    // Report a failed first-page search and allow it to be retried.
    if (_searchError != null && _portalItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to load web maps.'),
            TextButton(
              onPressed: () => _search(_searchController.text),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    // Explain when the current query returns no portal items.
    if (!_isSearching && _portalItems.isEmpty) {
      return const Center(child: Text('No results.'));
    }

    // Build rows and load another page as the list approaches its end.
    return ListView.builder(
      controller: _scrollController,
      itemCount: _portalItems.length + 1,
      itemBuilder: (context, index) {
        if (index == _portalItems.length) {
          return _buildPaginationStatus();
        }
        return _buildPortalItemRow(_portalItems[index]);
      },
    );
  }

  Widget _buildPortalItemRow(PortalItem item) {
    // Present the thumbnail, title, update date, and item owner together.
    final thumbnailUri = item.thumbnail?.uri;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: SizedBox(
        width: 96,
        height: 64,
        child: thumbnailUri != null
            ? Image.network(
                thumbnailUri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ThumbnailPlaceholder(),
              )
            : const _ThumbnailPlaceholder(),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_formatModifiedDate(item.modified)}  |  ${item.owner}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _openWebMap(item),
    );
  }

  Widget _buildPaginationStatus() {
    // Keep pagination feedback attached to the end of the result list.
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_searchError != null && _portalItems.isNotEmpty) {
      return Center(
        child: TextButton(
          onPressed: _loadNextPage,
          child: const Text('Could not load more results. Retry'),
        ),
      );
    }
    return const SizedBox(height: 16);
  }

  Future<void> _search(String query) async {
    // Invalidate older requests before updating the visible search state.
    final requestVersion = ++_searchVersion;
    final searchString = query.trim();
    setState(() {
      _portalItems.clear();
      _nextQueryParameters = null;
      _searchError = null;
      _isLoadingMore = false;
      _isSearching = searchString.isNotEmpty;
    });
    if (searchString.isEmpty) return;

    // Restrict the portal search to web maps and request its first result page.
    try {
      final parameters = PortalQueryParameters.forItems(
        types: const [PortalItemType.webMap],
        searchString: searchString,
      );
      final resultSet = await _portal.findItems(parameters: parameters);
      if (!mounted || requestVersion != _searchVersion) return;
      setState(() {
        _portalItems.addAll(resultSet.results);
        _nextQueryParameters = resultSet.nextQueryParameters;
        _isSearching = false;
      });
    } on Object catch (error) {
      if (!mounted || requestVersion != _searchVersion) return;
      setState(() {
        _searchError = error;
        _isSearching = false;
      });
    }
  }

  void _loadNextPageWhenNearEnd() {
    // Fetch another page when the user scrolls close to the final result.
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        _nextQueryParameters == null) {
      return;
    }
    if (_scrollController.position.extentAfter < 300) {
      unawaited(_loadNextPage());
    }
  }

  Future<void> _loadNextPage() async {
    // Reuse the portal-provided parameters to request the next result page.
    final queryParameters = _nextQueryParameters;
    if (queryParameters == null || _isLoadingMore) return;
    final requestVersion = _searchVersion;
    setState(() {
      _isLoadingMore = true;
      _searchError = null;
    });

    // Append only results that still belong to the active search.
    try {
      final resultSet = await _portal.findItems(parameters: queryParameters);
      if (!mounted || requestVersion != _searchVersion) return;
      setState(() {
        _portalItems.addAll(resultSet.results);
        _nextQueryParameters = resultSet.nextQueryParameters;
        _isLoadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted || requestVersion != _searchVersion) return;
      setState(() {
        _searchError = error;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _openWebMap(PortalItem item) async {
    // Open the selected portal item as a web map on a separate route.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => _WebMapPage(item: item)),
    );
  }

  String _formatModifiedDate(DateTime? modified) {
    // Show a readable local date or explain that no date is available.
    return modified?.toLocal().toString().split(' ').first ?? 'Date unknown';
  }

  @override
  void dispose() {
    // Release the controllers when the sample leaves the widget tree.
    _searchController.dispose();
    _scrollController
      ..removeListener(_loadNextPageWhenNearEnd)
      ..dispose();
    super.dispose();
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Use a neutral map symbol when a portal item has no thumbnail.
    return const ColoredBox(
      color: Color(0xFFE6E8EA),
      child: Center(child: Icon(Icons.map_outlined)),
    );
  }
}

class _WebMapPage extends StatelessWidget {
  const _WebMapPage({required this.item});

  final PortalItem item;

  @override
  Widget build(BuildContext context) {
    // Display the selected web map and show its loading or failure state.
    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () =>
                ArcGISMapView.createController()
                  ..arcGISMap = ArcGISMap.withItem(item),
          ),
        ],
      ),
    );
  }
}
