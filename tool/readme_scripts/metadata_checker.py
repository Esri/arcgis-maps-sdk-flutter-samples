#!/usr/bin/env python3
#
# Copyright 2025 Esri
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import argparse
import os
import json
from difflib import unified_diff
from common import *


def run_check(path: str, category: str) -> None:
    """
    Creates a sample's metadata by running the script against its path, and
    writes to a separate JSON for comparison.

    The path may look like /samples/display_map/
    """
    checker = (path, category)

    # 1. Populate from README.
    try:
        checker.populate_from_readme()
        checker.populate_from_paths()
    except Exception as err:
        print(f'Error: populate failed for - {checker.folder_name}.')
        raise err

    json_path = os.path.join(path, 'README.metadata.json')

    # 2. Load JSON.
    try:
        with open(json_path, 'r') as json_file:
            json_data = json.load(json_file)
    except Exception as err:
        print(f'Error reading JSON - {path} - {err}')
        raise err

    # Set the category
    checker.category = json_data.get('category')

    # Set the redirect_from
    checker.redirect_from = json_data.get('redirect_from')

    # Set optional fields
    checker.offline_data = json_data.get('offline_data')
    checker.class_name = json_data.get('className')

    # Special rule: lenient on shortened description
    if json_data['description'] in sub_special_char(checker.description):
        checker.description = json_data['description']

    # Special rule: ignore order of src filenames
    if sorted(json_data['snippets']) == checker.snippets:
        checker.snippets = json_data['snippets']

    # 3. Compare schema-based generated JSON to the source JSON
    new = checker.flush_to_json_string()
    original = json.dumps(json_data, indent=4, sort_keys=True)
    if new != original:
        expected = new.splitlines()
        actual = original.splitlines()
        diff = '\n'.join(unified_diff(expected, actual))
        raise Exception(f'Error: inconsistent metadata - {path} -\n{diff}')

    # 4. Check category
    try:
        checker.check_category()
    except Exception as err:
        raise Exception(f'{checker.folder_path} - {err}')


def main():
    msg = (
        'Metadata checker. Run it against a single sample folder. '
        'On success: Script will exit with zero. '
        'On failure: Style violations will print to console and the script '
        'will exit with non-zero code.'
    )
    parser = argparse.ArgumentParser(description=msg)
    parser.add_argument('-s', '--single', help='Path to a single sample')
    parser.add_argument('-c', '--category', help='The category for the sample')
    args = parser.parse_args()

    if args.single:
        run_check(args.single, args.category or "")
    else:
        raise Exception('Invalid arguments, abort.')



if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'{error}')
        exit(1)
