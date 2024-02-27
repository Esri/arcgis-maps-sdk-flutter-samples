//
// COPYRIGHT © 2023 Esri
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// This material is licensed for use under the Esri Master
// Agreement (MA) and is bound by the terms and conditions
// of that agreement.
//
// You may redistribute and use this code without modification,
// provided you adhere to the terms and conditions of the MA
// and include this copyright notice.
//
// See use restrictions at http://www.esri.com/legal/pdfs/mla_e204_e300/english
//
// For additional information, contact:
// Environmental Systems Research Institute, Inc.
// Attn: Contracts and Legal Department
// 380 New York Street
// Redlands, California 92373
// USA
//
// email: legal@esri.com
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
