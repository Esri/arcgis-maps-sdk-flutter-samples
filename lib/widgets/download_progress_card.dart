// Copyright 2026 Esri
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

/// A reusable, dialog-like card widget for displaying download/job progress.
class DownloadProgressCard extends StatelessWidget {
  const DownloadProgressCard({
    required this.title,
    required this.progress,
    super.key,
    this.onCancel,
    this.cancelLabel,
    this.showPercentage = true,
  });

  /// Title displayed at the top of the progress card.
  final String title;

  /// Progress value from 0.0 (0%) to 1.0 (100%).
  final double progress;

  /// Callback invoked when the cancel button is pressed.
  final VoidCallback? onCancel;

  /// Optional: Custom cancel button label (default: 'Cancel').
  final String? cancelLabel;

  /// Optional: Show percentage text (default: true)
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate percentage for display
    final percentage = (progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0);

    return Center(
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.7,
            minWidth: 280,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              // Title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              // Percentage text
              if (showPercentage)
                Text(
                  '$percentage%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              // Progress indicator (uses global ProgressIndicatorThemeData)
              LinearProgressIndicator(value: progress),

              // Progress description
              Text(
                '$percentage% completed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              // Cancel button
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCancel,
                    child: Text(cancelLabel ?? 'Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
