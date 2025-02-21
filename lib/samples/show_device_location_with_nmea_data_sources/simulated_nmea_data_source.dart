// Copyright 2025 Esri
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
import 'dart:async';
import 'dart:io';
import 'package:arcgis_maps_sdk_flutter_samples/common/common.dart';

import 'package:async/async.dart';
import 'package:path_provider/path_provider.dart';

class SimulatedNmeaDataSource {
  SimulatedNmeaDataSource({Duration interval = const Duration(seconds: 1)})
    : _interval = interval {
    _nmeaMessagesController.onListen = _start;
    _nmeaMessagesController.onCancel = _shutdown;

    // Create the timer for posting the messages.
    _timer = RestartableTimer(_interval, _postNextMessageBlock);
  }

  final Duration _interval;
  late final RestartableTimer _timer;
  var _running = false;
  var _currentNmeaBlockIndex = 0;
  final _sentencesByTimeBlock = <String>[];

  // Stream to provide the NMEA messages.
  final _nmeaMessagesController = StreamController<String>();
  Stream<String> get nmeaMessages => _nmeaMessagesController.stream;

  // Function to post the next block of NMEA sentences in the list to the stream.
  // If the end of the list is reached, the counter restarts from the beginning.
  void _postNextMessageBlock() {
    if (!_running) return;

    _nmeaMessagesController.add(_sentencesByTimeBlock[_currentNmeaBlockIndex]);
    // Increment the index. If the end is reached, start back at 0.
    _currentNmeaBlockIndex =
        _currentNmeaBlockIndex + 1 == _sentencesByTimeBlock.length
            ? 0
            : _currentNmeaBlockIndex + 1;

    _timer.reset();
  }

  // Download the sample NMEA file and read the contents into a list of messages
  // that combine all NMEA sentences for the same time into a single message string.
  Future<void> _initData() async {
    final nmeaSentences = await _loadNmeaFile();

    final messageSentences = <String>[];
    for (final sentence in nmeaSentences) {
      final sentenceComponents = sentence.split(',');
      // In this test data set, every block of sentences for a certain time starts with a GGA sentence.
      if (sentenceComponents[0].contains('GGA')) {
        if (messageSentences.isNotEmpty) {
          // Close out the prior block of sentences.
          // Join the sentences with a linefeed. Append an additional
          // linefeed to the end to properly terminate the last sentence.
          final groupedSentences = '${messageSentences.join('\n')}\n';
          _sentencesByTimeBlock.add(groupedSentences);
          messageSentences.clear();
        }
      }

      messageSentences.add(sentence);
    }
  }

  // Initialize the data and restart the timer.
  Future<void> _start() async {
    if (_running) return;

    if (_sentencesByTimeBlock.isEmpty) {
      // Load the NMEA data.
      await _initData();
    }

    _running = true;

    // Post the first block of sentences immediately.
    _postNextMessageBlock();

    // Reset the timer for the next interval.
    _timer.reset();
  }

  // Stops the simulator. Cancels the running timer and closes the stream.
  void _shutdown() {
    if (!_running) return;

    _nmeaMessagesController.close();
    if (_timer.isActive) _timer.cancel();
    _running = false;
  }

  // Downloads the sample NMEA data file and returns the NMEA sentences as a
  // list of Strings.
  Future<List<String>> _loadNmeaFile() async {
    // Download the file from arcgis.com.
    await downloadSampleData(['d5bad9f4fee9483791e405880fb466da']);
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/RedlandsNMEA/Redlands.nmea';
    final nmeaFile = File(filePath);

    // Read and return the file as a list of String lines.
    return nmeaFile.readAsLines();
  }
}
