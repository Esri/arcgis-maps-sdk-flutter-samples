import 'package:arcgis_maps_sdk_flutter_samples/samples/add_feature_collection_layer_from_table/add_feature_collection_layer_from_table.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_feature_layer_with_time_offset/add_feature_layer_with_time_offset.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_feature_layers/add_feature_layers.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_map_image_layer/add_map_image_layer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_tiled_layer/add_tiled_layer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_tiled_layer_as_basemap/add_tiled_layer_as_basemap.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/add_vector_tiled_layer/add_vector_tiled_layer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_class_breaks_renderer_to_sublayer/apply_class_breaks_renderer_to_sublayer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_scheduled_updates_to_preplanned_map_area/apply_scheduled_updates_to_preplanned_map_area.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_simple_renderer_to_feature_layer/apply_simple_renderer_to_feature_layer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/apply_unique_value_renderer/apply_unique_value_renderer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/authenticate_with_oauth/authenticate_with_oauth.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/authenticate_with_token/authenticate_with_token.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/create_mobile_geodatabase/create_mobile_geodatabase.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/create_planar_and_geodetic_buffers/create_planar_and_geodetic_buffers.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/cut_geometry/cut_geometry_sample.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/densify_and_generalize_geometry/densify_and_generalize_geometry.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/display_clusters/display_clusters.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/display_map/display_map.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/display_map_from_mobile_map_package/display_map_from_mobile_map_package.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/download_preplanned_map_area/download_preplanned_map_area.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/download_vector_tiles_to_local_cache/download_vector_tiles_to_local_cache.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/edit_feature_attachments/edit_feature_attachments.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/filter_by_definition_expression_or_display_filter/filter_by_definition_expression_or_display_filter.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/find_address_with_reverse_geocode/find_address_with_reverse_geocode.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/find_closest_facility_from_point/find_closest_facility_from_point.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/find_route/find_route.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/generate_offline_map/generate_offline_map.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/identify_layer_features/identify_layer_features.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/manage_bookmarks/manage_bookmarks.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/query_feature_table/query_feature_table.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/query_table_statistics/query_table_statistics.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/select_features_in_feature_layer/select_features_in_feature_layer.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/set_basemap/set_basemap.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/set_reference_scale/set_reference_scale.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_device_location/show_device_location.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_device_location_history/show_device_location_history.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_grid/show_grid.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_legend/show_legend.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_magnifier/show_magnifier.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_portal_user_info/show_portal_user_info.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/show_service_area/show_service_area.dart';
import 'package:arcgis_maps_sdk_flutter_samples/samples/style_point_with_simple_marker_symbol/style_point_with_simple_marker_symbol.dart';

// A list of all the Widgets for individual Samples.
// Used by the Sample Viewer App to display the Widget when a sample is selected.
// The key is the directory name for the sample which is in snake case. E.g. display_map
final sampleWidgets = <String, Function>{
  'add_feature_collection_layer_from_table': () =>
      const AddFeatureCollectionLayerFromTable(),
  'add_feature_layer_with_time_offset': () =>
      const AddFeatureLayerWithTimeOffset(),
  'add_feature_layers': () => const AddFeatureLayers(),
  'add_map_image_layer': () => const AddMapImageLayer(),
  'add_tiled_layer': () => const AddTiledLayer(),
  'add_tiled_layer_as_basemap': () => const AddTiledLayerAsBasemap(),
  'add_vector_tiled_layer': () => const AddVectorTiledLayer(),
  'apply_class_breaks_renderer_to_sublayer': () =>
      const ApplyClassBreaksRendererToSublayer(),
  'apply_scheduled_updates_to_preplanned_map_area': () =>
      const ApplyScheduledUpdatesToPreplannedMapArea(),
  'apply_simple_renderer_to_feature_layer': () =>
      const ApplySimpleRendererToFeatureLayer(),
  'apply_unique_value_renderer': () => const ApplyUniqueValueRenderer(),
  'authenticate_with_oauth': () => const AuthenticateWithOAuth(),
  'authenticate_with_token': () => const AuthenticateWithToken(),
  'create_mobile_geodatabase': () => const CreateMobileGeodatabase(),
  'create_planar_and_geodetic_buffers': () =>
      const CreatePlanarAndGeodeticBuffers(),
  'cut_geometry': () => const CutGeometrySample(),
  'densify_and_generalize_geometry': () => const DensifyAndGeneralizeGeometry(),
  'display_clusters': () => const DisplayClusters(),
  'display_map': () => const DisplayMap(),
  'display_map_from_mobile_map_package': () =>
      const DisplayMapFromMobileMapPackage(),
  'download_preplanned_map_area': () => const DownloadPreplannedMapArea(),
  'download_vector_tiles_to_local_cache': () =>
      const DownloadVectorTilesToLocalCache(),
  'edit_feature_attachments': () => const EditFeatureAttachments(),
  'filter_by_definition_expression_or_display_filter': () =>
      const FilterByDefinitionExpressionOrDisplayFilter(),
  'find_address_with_reverse_geocode': () =>
      const FindAddressWithReverseGeocode(),
  'find_closest_facility_from_point': () =>
      const FindClosestFacilityFromPoint(),
  'find_route': () => const FindRoute(),
  'generate_offline_map': () => const GenerateOfflineMap(),
  'identify_layer_features': () => const IdentifyLayerFeatures(),
  'manage_bookmarks': () => const ManageBookmarks(),
  'query_feature_table': () => const QueryFeatureTable(),
  'query_table_statistics': () => const QueryTableStatistics(),
  'select_features_in_feature_layer': () =>
      const SelectFeaturesInFeatureLayer(),
  'set_basemap': () => const SetBasemap(),
  'set_reference_scale': () => const SetReferenceScale(),
  'show_device_location': () => const ShowDeviceLocation(),
  'show_device_location_history': () => const ShowDeviceLocationHistory(),
  'show_grid': () => const ShowGrid(),
  'show_magnifier': () => const ShowMagnifier(),
  'show_portal_user_info': () => const ShowPortalUserInfo(),
  'show_service_area': () => const ShowServiceArea(),
  'show_legend': () => const ShowLegend(),
  'style_point_with_simple_marker_symbol': () =>
      const StylePointWithSimpleMarkerSymbol(),
};
