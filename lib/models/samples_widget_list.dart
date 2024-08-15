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
import 'package:arcgis_maps_sdk_flutter_samples/samples/cut_geometry/cut_geometry.dart';
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
import 'package:arcgis_maps_sdk_flutter_samples/samples/identify_graphics/identify_graphics.dart';
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

final sampleWidgets = {
  'AddFeatureCollectionLayerFromTable': () =>
      const AddFeatureCollectionLayerFromTable(),
  'AddFeatureLayerWithTimeOffset': () => const AddFeatureLayerWithTimeOffset(),
  'AddFeatureLayers': () => const AddFeatureLayers(),
  'AddMapImageLayer': () => const AddMapImageLayer(),
  'AddTiledLayer': () => const AddTiledLayer(),
  'AddTiledLayerAsBasemap': () => const AddTiledLayerAsBasemap(),
  'AddVectorTiledLayer': () => const AddVectorTiledLayer(),
  'ApplyClassBreaksRendererToSublayer': () =>
      const ApplyClassBreaksRendererToSublayer(),
  'ApplyScheduledUpdatesToPreplannedMapArea': () =>
      const ApplyScheduledUpdatesToPreplannedMapArea(),
  'ApplySimpleRendererToFeatureLayer': () =>
      const ApplySimpleRendererToFeatureLayer(),
  'ApplyUniqueValueRenderer': () => const ApplyUniqueValueRenderer(),
  'AuthenticateWithOAuth': () => const AuthenticateWithOAuth(),
  'AuthenticateWithToken': () => const AuthenticateWithToken(),
  'CreateMobileGeodatabase': () => const CreateMobileGeodatabase(),
  'CreatePlanarAndGeodeticBuffers': () =>
      const CreatePlanarAndGeodeticBuffers(),
  'CutGeometry': () => const CutGeometry(),
  'DensifyAndGeneralizeGeometry': () => const DensifyAndGeneralizeGeometry(),
  'DisplayClusters': () => const DisplayClusters(),
  'DisplayMap': () => const DisplayMap(),
  'DisplayMapFromMobileMapPackage': () =>
      const DisplayMapFromMobileMapPackage(),
  'DownloadPreplannedMapArea': () => const DownloadPreplannedMapArea(),
  'DownloadVectorTilesToLocalCache': () =>
      const DownloadVectorTilesToLocalCache(),
  'EditFeatureAttachments': () => const EditFeatureAttachments(),
  'FilterByDefinitionExpressionOrDisplayFilter': () =>
      const FilterByDefinitionExpressionOrDisplayFilter(),
  'FindAddressWithReverseGeocode': () => const FindAddressWithReverseGeocode(),
  'FindClosestFacilityFromPoint': () => const FindClosestFacilityFromPoint(),
  'FindRoute': () => const FindRoute(),
  'GenerateOfflineMap': () => const GenerateOfflineMap(),
  'IdentifyGraphics': () => const IdentifyGraphics(),
  'IdentifyLayerFeatures': () => const IdentifyLayerFeatures(),
  'ManageBookmarks': () => const ManageBookmarks(),
  'QueryFeatureTable': () => const QueryFeatureTable(),
  'QueryTableStatistics': () => const QueryTableStatistics(),
  'SelectFeaturesInFeatureLayer': () => const SelectFeaturesInFeatureLayer(),
  'SetBasemap': () => const SetBasemap(),
  'SetReferenceScale': () => const SetReferenceScale(),
  'ShowDeviceLocation': () => const ShowDeviceLocation(),
  'ShowDeviceLocationHistory': () => const ShowDeviceLocationHistory(),
  'ShowGrid': () => const ShowGrid(),
  'ShowLegend': () => const ShowLegend(),
  'ShowMagnifier': () => const ShowMagnifier(),
  'ShowPortalUserInfo': () => const ShowPortalUserInfo(),
  'ShowServiceArea': () => const ShowServiceArea(),
  'StylePointWithSimpleMarkerSymbol': () =>
      const StylePointWithSimpleMarkerSymbol(),
};
