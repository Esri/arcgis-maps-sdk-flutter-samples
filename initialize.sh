#!/bin/bash -ev

# Configure the package dependencies.
flutter pub upgrade

# Install arcgis_maps_core.
dart run arcgis_maps install

# Generate support code.
dart run build_runner build

# Format generated code.
dart format lib/models/samples_widget_list.dart
