# ArcGIS Maps SDK for Flutter Samples

This repository contains Flutter sample code demonstrating the capabilities of ArcGIS Maps SDK for Flutter and how to use them in your own app. This SDK enables development of cross-platform GIS apps for mobile devices running iOS and Android.

## Running the Samples app

The app can be run on an iOS or Android simulator or device.

- Open the flutter project in VSCode
- Ensure a simulator is running or a device is connected to your development machine 
- Open the "Run and Debug" sidebar
- Select which device or simulator you wish to use in the lower right corner of the VSCode window
- Select "Samples (debug or release)"
  - Note that "Samples (release)" can only be run on a device
- Click the run button or press F5

## Running individual samples

Individual samples can also be run on an iOS or Android simulator or device.

- Open the flutter project in VSCode
- Ensure a simulator is running or a device is connected to your development machine
- Select which device or simulator you wish to use in the lower right corner of the VSCode window
- To run from VSCode, open a sample file from `/lib/src/samples` e.g. `display_map.dart` and click `run` above the `main()` method
- Or run from the command line with `flutter run lib/src/samples/display_map.dart`

## Configuring API Keys

To fully take advantage of the samples in the app, you will need to generate an API Key.

- Log into your developer account at the [ArcGIS Developers](https://developers.arcgis.com/)
  - If you do not have an account, [create one](https://developers.arcgis.com/sign-up/)
- Go to the "API keys" tab
- Click the "New API Key" button and provide a Title and Description
- Set Location Service scopes to add or remove key capabilities

Add the new API Key directly to [main.dart](lib/main.dart) or create an environment JSON file that can be loaded with the `--dart-define-from-file` `flutter run` command line argument. 

```
flutter run --dart-define-from-file=path/to/json/file.json
```

or to run an individual sample:

```
flutter run  lib/src/samples/display_map.dart --dart-define-from-file=path/to/json/file.json
```

## Licensing
Copyright 2024 Esri

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

A copy of the license is available in the repository's LICENSE file.
