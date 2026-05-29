---
name: create-new-sample
description: Scaffolds, implements, and validates a new Flutter sample based on existing designs.
---

# Inputs

- sample_name: The name of the sample in sentence case (e.g., "Analyze
	hotspots").
- sample_category: The category of the sample (e.g., "Analysis",
	"Visualization").
- design_directory: The directory containing the design files for the sample,
	located in `../common-samples/designs/`.
- documentation_directory: Path to the API docs at
	`../flutter/arcgis_maps/doc/api/`.

# Expected Outputs

- New sample directory: `lib/samples/<sample_name_snake_case>/`
- Sample implementation file(s)
- Sample `README.md`
- Required registration updates so the sample appears in the app
- `AGENT_REPORT.md` detailing execution status

# Agent Workflow

## Phase 1: Strict Validation & Setup

1. Validate that the user provided `sample_name`. If not provided, prompt the
	user to input it. Ensure it is in sentence case. If the input is malformed,
	halt execution.
2. Verify the `design_directory` exists. If not found, halt execution.
3. Validate that the user provided `sample_category` or that
	`sample_category` can be determined from the
	`implementation-details.md` file in the design directory. If it cannot be
	determined, halt execution.
4. Verify the `documentation_directory` exists and contains API reference
	files. If not found, halt execution.

## Phase 2: Scaffolding

Execute the scaffolding script:

```bash
dart tool/generate_new_sample.dart "<sample_name>" "<sample_category>"
```

If the script returns a non-zero exit code, halt execution and report the console error.

## Phase 3: Targeted Context Gathering

Read the `implementation-details.md` file located within the provided `design_directory`.

Locate the corresponding Swift and Kotlin implementations by querying the repos defined in `AGENTS.md`.

Read only the core controller/view files from those cross-platform samples to
identify the primary ArcGIS mapping classes and architectural patterns
required.

## Phase 4: Deterministic Implementation

Use the scaffolded Dart files as your foundation.

Translate the logic identified in Phase 3 into Dart/Flutter.

API Reference Protocol: Do not attempt to ingest the entire
`documentation_directory`. Instead, cross-reference the specific ArcGIS
classes identified in Phase 3 by reading only their corresponding Dart
documentation files within `../flutter/arcgis_maps/doc/api/`.

If a specific API file is missing, leave a
`// TODO: Implement <Feature> - API doc missing` comment in the Dart code and
continue.

## Phase 5: State Synchronization

Execute the initialization script to regenerate affected code:

```bash
dart tool/initialize.dart
```

If this fails, do not attempt to fix the generator script. Halt and report the failure.

## Phase 6: Validation and Structured Reporting

Run `flutter analyze` against the newly created sample directory.

Circuit Breaker: Attempt to resolve any detected analysis issues. You are
permitted a maximum of 3 iterative fix attempts. If issues persist after 3
attempts, cease fixing.

Generate a file named `AGENT_REPORT.md` in the new sample directory. This file
must contain a markdown table reporting the pass, fail, or skip status of the
following stages: Scaffolding, Implementation, Initialization, and Analysis.
Include a brief notes column for any captured console errors or missing API
files.
