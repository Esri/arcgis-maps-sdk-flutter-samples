rem Configure the package dependencies.
call flutter pub upgrade

rem Install arcgis_maps_core.
call dart run arcgis_maps install

rem Generate support code.
call dart run build_runner build

rem Format generated code.
call dart format lib/models/samples_widget_list.dart
