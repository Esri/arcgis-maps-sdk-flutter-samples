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

import 'package:flutter/material.dart';
import 'sample_info_list.dart';

class SampleListView extends StatelessWidget {
  const SampleListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sampleInfoList.length,
      itemBuilder: (context, index) {
        final sampleInfo = sampleInfoList[index];
        return Card(
          child: ListTile(
            title: Text(sampleInfo.title),
            subtitle: Text(sampleInfo.description),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => sampleInfo.getSample()),
              );
            },
          ),
        );
      },
    );
  }
}
