# Agent Guide

## Purpose

Basic guidance for coding agents and contributors working in this repository.

## Repository summary

- **Project:** ArcGIS Maps SDK for Flutter samples application
- **Main language:** Dart
- **Framework:** Flutter
- **Primary app code:** `lib/`

## Key paths

- `lib/samples/`: Individual sample implementations
- `lib/common/`: Shared app and sample infrastructure
- `lib/widgets/`: Reusable UI components
- `assets/`: Sample data, images, and static resources
- `tool/`: Utility scripts for generating and maintaining samples
- `android/`, `ios/`: Platform host projects

## Build workflow

1. Run `dart tool/initialize.dart` to perform the special `arcgis_maps` install
   step and run code generation.
2. Build platforms with `flutter build apk` and `flutter build ios`.
3. If `../flutter/arcgis_maps/test/env.json` exists, pass it to `flutter build`
   using `--dart-define-from-file`.

## Design repo

Each sample has a design document in the `common-samples` repository, cloned to
`../common-samples`.

Design docs are stored in `../common-samples/designs/`. Each subdirectory
represents one design and uses the sample name in CamelCase. The matching sample
directory under `lib/samples/` uses snake_case.
