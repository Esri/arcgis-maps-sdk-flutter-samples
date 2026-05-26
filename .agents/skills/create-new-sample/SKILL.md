---
name: create-new-sample
description: Stub in a new sample and implement it.
---
# Inputs
- Sample name
- Sample category
- Design doc path from `../common-samples/designs/`

# Expected outputs
- New sample directory: `lib/samples/<sample_name_snake_case>/`
- Sample implementation file(s)
- Sample `README.md`
- Any required registration updates so the sample appears in the
  app

If the expected directory is not created, report an error and
stop the process.

# Workflow

## 1. Determine the Sample name, category, and design doc path

If the user did not specify Sample name and category, prompt the
user to input them. The Sample name should be in Title Case
(e.g., "Analyze Hotspots") and the category should be one of
the existing categories (e.g., "Analysis", "Visualization",
etc.).

The design doc must be available in `../common-samples/designs/`.
If it cannot be located, or if the Sample name or category does not
match, report an error and stop the process.

## 2. Run the `generate_new_sample.dart` script

Run `dart tool/generate_new_sample.dart` passing the Sample name
and the Sample category as arguments. For example:
```bash
dart tool/generate_new_sample.dart "Analyze Hotspots" "Analysis"
```

If the script returns a non-zero exit code, report the error and
stop the process.

## 3. Locate other implementations of the sample

Check the Swift and Kotlin samples repos (as described in
AGENTS.md) for existing implementations of the sample. If found,
note their locations for reference during implementation.

## 4. Implement the sample

Use the generated sample files as a starting point. Refer to the
design doc and any existing implementations in other languages to
implement the sample in Dart/Flutter. Follow existing patterns and
conventions used in other samples.

## 5. Run the initialize step

After implementing the sample, run `dart tool/initialize.dart` to
regenerate any affected code and update the project state.

## 6. Check for analyze issues

Run `flutter analyze` to check for any issues in the code. Address
any issues that are found.

