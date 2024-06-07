# ArcGIS Maps SDK for Flutter Samples

This repository contains Flutter sample code demonstrating the capabilities of ArcGIS Maps SDK for Flutter and how to use them in your own app. This SDK enables development of cross-platform GIS apps for mobile devices running iOS and Android.

## Run the samples using the Beta package of ArcGIS Maps SDK for Flutter

Visit [earlyadopter.esri.com](https://earlyadopter.esri.com/) and download the ArcGIS Maps SDK for Flutter package. Follow the instructions to unpack it.

Clone or download this repository into the same parent directory as the `arcgis_maps_package`.

Note on Windows: This repository uses symlinks. Git must be configured to use symlinks and have permission to create symlinks. To configure git, run `git config --system core.symlinks true`. To have permission to create symlinks, either clone the repository in an elevated "Administrator" command prompt, or go to "Settings > Update & Security > For developers" and turn on "Developer Mode".

Your file structure should be:

```
parent_directory
   |
   |__ arcgis-maps-sdk-flutter-samples
   |
   |__ arcgis_maps_package
```

Navigate to the `arcgis-maps-sdk-flutter-samples` directory.

```
cd arcgis-maps-sdk-flutter-samples
```

Use `flutter pub upgrade` to configure the dependencies.

```
flutter pub upgrade
```

Install arcgis_maps_core.

Note on Windows: this step requires permission to create symlinks. Either run this step in an elevated "Administrator" command prompt, or go to "Settings > Update & Security > For developers" and turn on "Developer Mode".

```
dart run arcgis_maps install
```

Now you are ready to run the samples app!

## Running the Samples app

The app can be run on an iOS or Android simulator or device. Note: you will need to configure an API key to take full advantage of the samples in the app. See [Configuring API Keys](#configuring-api-keys).

- Open the flutter project in VSCode
- Ensure a simulator is running or a device is connected to your development machine 
- Open the "Run and Debug" sidebar
- Select which device or simulator you wish to use in the lower right corner of the VSCode window
- Select "Sample Viewer App (debug or release)"
  - Note that "Sample Viewer App (release)" can only be run on a device
- Click the run button or press F5

## Running individual samples

Individual samples can also be run on an iOS or Android simulator or device.

- Open the flutter project in VSCode
- Ensure a simulator is running or a device is connected to your development machine
- Select which device or simulator you wish to use in the lower right corner of the VSCode window
- To run from VSCode, open `lib/utils/sample_runner.dart` and define the sample you want to run
- Or run from the command line with `flutter run lib/utils/sample_runner.dart --dart-define=SAMPLE=display_map`

## Configuring API Keys

To take full advantage of the samples in the app, you will need to generate an API Key.

- Log into your developer account at [ArcGIS Developers](https://developers.arcgis.com/)
  - If you do not have an account, [create one](https://developers.arcgis.com/sign-up/)
- Go to the "API keys" tab
- Click the "New API Key" button and provide a Title and Description
- Set Location Service scopes to add or remove key capabilities

Add the new API Key directly to [main.dart](lib/main.dart) or create an environment JSON file that can be loaded with the `--dart-define-from-file` `flutter run` command line argument.

The JSON file itself should be of the format:

```
{
    "API_KEY": "your_api_key_here"
}
```

To run the Sample Viewer App using the JSON file to define your API key:

```
flutter run --dart-define-from-file=path/to/json/file.json
```

## Licensing
Copyright 2024 Esri

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

A copy of the license is available in the repository's LICENSE file.
