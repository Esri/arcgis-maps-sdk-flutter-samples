import 'package:arcgis_maps_sdk_flutter_samples/samples/add_feature_collection_layer_from_table/add_feature_collection_layer_from_table_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_feature_layers/add_feature_layers_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_map_image_layer/add_map_image_layer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_tiled_layer/add_tiled_layer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_tiled_layer_as_basemap/add_tiled_layer_as_basemap_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_vector_tiled_layer/add_vector_tiled_layer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_class_breaks_renderer_to_sublayer/apply_class_breaks_renderer_to_sublayer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_scheduled_updates_to_preplanned_map_area/apply_scheduled_updates_to_preplanned_map_area_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_simple_renderer_to_feature_layer/apply_simple_renderer_to_feature_layer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_unique_value_renderer/apply_unique_value_renderer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/authenticate_with_oauth/authenticate_with_oauth_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/authenticate_with_token/authenticate_with_token_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/create_mobile_geodatabase/create_mobile_geodatabase_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/create_planar_and_geodetic_buffers/create_planar_and_geodetic_buffers_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/densify_and_generalize_geometry/densify_and_generalize_geometry_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/display_clusters/display_clusters_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/display_map/display_map_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/display_map_from_mobile_map_package/display_map_from_mobile_map_package_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/download_preplanned_map_area/download_preplanned_map_area_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/edit_feature_attachments/edit_feature_attachments_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/filter_by_definition_expression_or_display_filter/filter_by_definition_expression_or_display_filter_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/find_address_with_reverse_geocode/find_address_with_reverse_geocode_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/find_closest_facility_from_point/find_closest_facility_from_point_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/find_route/find_route_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/generate_offline_map/generate_offline_map_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/identify_layer_features/identify_layer_features_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/manage_bookmarks/manage_bookmarks_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/query_feature_table/query_feature_table_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/query_table_statistics/query_table_statistics_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/select_features_in_feature_layer/select_features_in_feature_layer_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/set_basemap/set_basemap_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_device_location/show_device_location_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_device_location_history/show_device_location_history_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_grid/show_grid_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_legend/show_legend_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_magnifier/show_magnifier_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_portal_user_info/show_portal_user_info_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_service_area/show_service_area_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/style_point_with_simple_marker_symbol/style_point_with_simple_marker_symbol_sample.dart';
import 'package:flutter/material.dart';

// A list of all the Widgets for individual Samples.
// Used by the Sample Viewer App to display the Widget when a sample is selected.
// The key is the directory name for the sample which is in snake case. E.g. display_map
const sampleWidgets = <String, Widget>{
  'add_feature_collection_layer_from_table':
      AddFeatureCollectionLayerFromTableSample(),
  'add_feature_layers': AddFeatureLayersSample(),
  'add_map_image_layer': AddMapImageLayerSample(),
  'add_tiled_layer': AddTiledLayerSample(),
  'add_tiled_layer_as_basemap': AddTiledLayerAsBasemapSample(),
  'add_vector_tiled_layer': AddVectorTiledLayerSample(),
  'apply_class_breaks_renderer_to_sublayer':
      ApplyClassBreaksRendererToSublayerSample(),
  'apply_scheduled_updates_to_preplanned_map_area':
      ApplyScheduledUpdatesToPreplannedMapAreaSample(),
  'apply_simple_renderer_to_feature_layer':
      ApplySimpleRendererToFeatureLayerSample(),
  'apply_unique_value_renderer': ApplyUniqueValueRendererSample(),
  'authenticate_with_oauth': AuthenticateWithOAuthSample(),
  'authenticate_with_token': AuthenticateWithTokenSample(),
  'create_mobile_geodatabase': CreateMobileGeodatabaseSample(),
  'create_planar_and_geodetic_buffers': CreatePlanarAndGeodeticBuffersSample(),
  'densify_and_generalize_geometry': DensifyAndGeneralizeGeometrySample(),
  'display_clusters': DisplayClustersSample(),
  'display_map': DisplayMapSample(),
  'display_map_from_mobile_map_package': DisplayMapFromMobileMapPackageSample(),
  'download_preplanned_map_area': DownloadPreplannedMapAreaSample(),
  'edit_feature_attachments': EditFeatureAttachmentsSample(),
  'filter_by_definition_expression_or_display_filter':
      FilterByDefinitionExpressionOrDisplayFilterSample(),
  'find_address_with_reverse_geocode': FindAddressWithReverseGeocodeSample(),
  'find_closest_facility_from_point': FindClosestFacilityFromPointSample(),
  'find_route': FindRouteSample(),
  'generate_offline_map': GenerateOfflineMapSample(),
  'identify_layer_features': IdentifyLayerFeaturesSample(),
  'manage_bookmarks': ManageBookmarksSample(),
  'query_feature_table': QueryFeatureTableSample(),
  'query_table_statistics': QueryTableStatisticsSample(),
  'select_features_in_feature_layer': SelectFeaturesInFeatureLayerSample(),
  'set_basemap': SetBasemapSample(),
  'show_device_location': ShowDeviceLocationSample(),
  'show_device_location_history': ShowDeviceLocationHistorySample(),
  'show_grid': ShowGridSample(),
  'show_magnifier': ShowMagnifierSample(),
  'show_portal_user_info': ShowPortalUserInfoSample(),
  'show_service_area': ShowServiceAreaSample(),
  'show_legend': ShowLegendSample(),
  'style_point_with_simple_marker_symbol':
      StylePointWithSimpleMarkerSymbolSample(),
};
