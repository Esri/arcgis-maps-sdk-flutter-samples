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

typedef SampleBuilder<T> = T Function(String title);

/// Class that contains information about each of the samples. The
/// title and description are shown in the list Card for the sample,
/// the title is used in the AppBar of the sample page, and the getSample
/// function instantiates the sample widget.
class SampleInfo<T> {
  final String name;
  final String title;
  final String description;
  final SampleBuilder<T> _builder;

  SampleInfo({
    required this.name,
    required this.title,
    required this.description,
    required SampleBuilder<T> builder,
  }) : _builder = builder;

  T getSample() => _builder(title);
}
