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

import 'sample_info.dart';
import 'samples/add_feature_collection_layer_from_table_sample.dart';
import 'samples/add_feature_layers_sample.dart';
import 'samples/add_tiled_layer_as_basemap_sample.dart';
import 'samples/add_tiled_layer_sample.dart';
import 'samples/add_vector_tiled_layer_sample.dart';
import 'samples/apply_scheduled_updates_to_preplanned_map_area_sample.dart';
import 'samples/apply_simple_renderer_to_feature_layer_sample.dart';
import 'samples/apply_unique_value_renderer_sample.dart';
import 'samples/change_sublayer_renderer_sample.dart';
import 'samples/display_map_sample.dart';
import 'samples/display_points_using_clustering_feature_reduction_sample.dart';
import 'samples/filter_by_definition_expression_or_display_filter_sample.dart';
import 'samples/find_address_sample.dart';
import 'samples/find_closest_facility_sample.dart';
import 'samples/generate_route_with_directions_sample.dart';
import 'samples/identify_layers_sample.dart';
import 'samples/open_mobile_map_sample.dart';
import 'samples/preplanned_offline_map_sample.dart';
import 'samples/query_feature_table_sample.dart';
import 'samples/query_table_statistics_sample.dart';
import 'samples/select_features_in_feature_layer_sample.dart';
import 'samples/serialize_feature_collection_sample.dart';
import 'samples/service_area_sample.dart';
import 'samples/set_basemap_sample.dart';
import 'samples/show_location_sample.dart';
import 'samples/show_magnifier_sample.dart';
import 'samples/simple_marker_symbol_sample.dart';
import 'samples/simulate_location_sample.dart';
import 'samples/suggest_address_sample.dart';

final List<SampleInfo> sampleInfoList = [
  SampleInfo(
    name: 'add_feature_collection_layer_from_table',
    title: 'Add Feature Collection Layer',
    description: 'Adds a FeatureCollectionLayer to the map.',
    builder: (title) => AddFeatureCollectionLayerFromTableSample(title: title),
  ),
  SampleInfo(
    name: 'add_feature_layers',
    title: 'Add Feature Layers',
    description: 'Select FeatureLayers to add to the map.',
    builder: (title) => AddFeatureLayersSample(title: title),
  ),
  SampleInfo(
    name: 'add_tiled_layer',
    title: 'Add Tiled Layer',
    description: 'Add a Tiled Layer to the map.',
    builder: (title) => AddTiledLayerSample(title: title),
  ),
  SampleInfo(
    name: 'add_tiled_layer_as_basemap',
    title: 'Add Tiled Layer Basemap',
    description: 'Use a Tiled Layer as the map\'s basemap.',
    builder: (title) => AddTiledLayerAsBasemapSample(title: title),
  ),
  SampleInfo(
    name: 'add_vector_tiled_layer',
    title: 'Add Vector Tile Layer',
    description: 'Add a Vector Tile Layer to the map.',
    builder: (title) => AddVectorTiledLayerSample(title: title),
  ),
  SampleInfo(
    name: 'apply_scheduled_updates_to_preplanned_map_area',
    title: 'Apply Scheduled Updates to Preplanned Map Area',
    description: 'Apply scheduled updates to a preplanned offline map.',
    builder: (title) =>
        ApplyScheduledUpdatesToPreplannedMapAreaSample(title: title),
  ),
  SampleInfo(
    name: 'apply_simple_renderer_to_feature_layer',
    title: 'Apply Simple Renderer',
    description: 'Apply a Simple Renderer to a Feature Layer.',
    builder: (title) => ApplySimpleRendererToFeatureLayerSample(title: title),
  ),
  SampleInfo(
    name: 'apply_unique_value_renderer',
    title: 'Apply Unique Value Renderer',
    description: 'Apply a Unique Value Renderer to a Feature Layer.',
    builder: (title) => ApplyUniqueValueRendererSample(title: title),
  ),
  SampleInfo(
    name: 'change_sublayer_renderer',
    title: 'Change Sublayer Renderer',
    description: 'Change the renderer of a sublayer of a map image layer.',
    builder: (title) => ChangeSublayerRendererSample(title: title),
  ),
  SampleInfo(
    name: 'display_map',
    title: 'Display Map',
    description: 'Show a map with a basemap.',
    builder: (title) => DisplayMapSample(title: title),
  ),
  SampleInfo(
    name: 'display_points_using_clustering_feature_reduction',
    title: 'Feature Point Clustering',
    description: 'Dynamically cluster points to reduce displayed features.',
    builder: (title) =>
        DisplayPointsUsingClusteringFeatureReductionSample(title: title),
  ),
  SampleInfo(
    name: 'filter_by_definition_expression_or_display_filter',
    title: 'Filter Features',
    description:
        'Filter map features by Definition Expression or Display Filter.',
    builder: (title) =>
        FilterByDefinitionExpressionOrDisplayFilterSample(title: title),
  ),
  SampleInfo(
    name: 'find_address',
    title: 'Find Address',
    description:
        'Find location by address using worldwide or San Diego lookup.',
    builder: (title) => FindAddressSample(title: title),
  ),
  SampleInfo(
    name: 'find_closest_facility',
    title: 'Find Closest Facility',
    description:
        'For multiple points, find the facility closest to each point and generate a route to it.',
    builder: (title) => FindClosestFacilitySample(title: title),
  ),
  SampleInfo(
    name: 'generate_route_with_directions',
    title: 'Generate Route',
    description: 'Generate a route with driving directions.',
    builder: (title) => GenerateRouteWithDirectionsSample(title: title),
  ),
  SampleInfo(
    name: 'identify_layers',
    title: 'Identify Layers',
    description: 'Identify features by tapping on the map.',
    builder: (title) => IdentifyLayersSample(title: title),
  ),
  SampleInfo(
    name: 'open_mobile_map',
    title: 'Open Mobile Map',
    description: 'Load a mobile map package from a local file.',
    builder: (title) => OpenMobileMapSample(title: title),
  ),
  SampleInfo(
    name: 'preplanned_offline_map',
    title: 'Preplanned Offline Map',
    description: 'Load preplanned maps that can be used offline from a server.',
    builder: (title) => PreplannedOfflineMapSample(title: title),
  ),
  SampleInfo(
    name: 'query_feature_table',
    title: 'Query Feature Table',
    description: 'Query for features from a Feature Table.',
    builder: (title) => QueryFeatureTableSample(title: title),
  ),
  SampleInfo(
    name: 'query_table_statistics',
    title: 'Query Table Statistics',
    description:
        'Query statistics from a Feature Table. Change query scope to see differences.',
    builder: (title) => QueryTableStatisticsSample(title: title),
  ),
  SampleInfo(
    name: 'select_features_in_feature_layer',
    title: 'Select Features',
    description: 'Select features on a map by tapping them.',
    builder: (title) => SelectFeaturesInFeatureLayerSample(title: title),
  ),
  SampleInfo(
    name: 'serialize_feature_collection',
    title: 'Serialize Feature Collection',
    description:
        'Serialize features to disk and reload features at next launch.',
    builder: (title) => SerializeFeatureCollectionSample(title: title),
  ),
  SampleInfo(
    name: 'service_area',
    title: 'Service Area',
    description: 'Show service areas based on drive time from a point.',
    builder: (title) => ServiceAreaSample(title: title),
  ),
  SampleInfo(
    name: 'set_basemap',
    title: 'Set Basemap',
    description: 'Change the basemap for the map.',
    builder: (title) => SetBasemapSample(title: title),
  ),
  SampleInfo(
    name: 'show_location',
    title: 'Show Location',
    description: 'Show current location using the device\'s location services.',
    builder: (title) => ShowLocationSample(title: title),
  ),
  SampleInfo(
    name: 'show_magnifier',
    title: 'Show Magnifier',
    description: 'Long press on the map to show the map magnifier.',
    builder: (title) => ShowMagnifierSample(title: title),
  ),
  SampleInfo(
    name: 'simple_marker_symbol',
    title: 'Simple Marker Symbol',
    description: 'Show a Simple Marker Symbol on the map.',
    builder: (title) => SimpleMarkerSymbolSample(title: title),
  ),
  SampleInfo(
    name: 'simulate_location',
    title: 'Simulate Location',
    description: 'Load a polyline to use to simulate location',
    builder: (title) => SimulateLocationSample(title: title),
  ),
  SampleInfo(
    name: 'suggeset_address',
    title: 'Suggest Address',
    description: 'Start typing an address and see completion suggestions.',
    builder: (title) => SuggestAddressSample(title: title),
  ),
];
