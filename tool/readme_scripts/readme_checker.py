#!/usr/bin/env python3
#
# Copyright 2024 Esri
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

"""
Comments in PyCharm style.

References

- Tag sorter
  /common-samples/blob/main/tools/net/tag_sorter/tag_sorter.py

- README standard format
  /common-samples/wiki/README-Template
"""

import argparse
from common import *


def run_check(path: str, count: int) -> int:
    checker = Readme(path)
    # 1. Populate from README.
    try:
        checker.populate_from_readme()
    except Exception as err:
        count += 1
        print(f'{count}. {checker.folder_path} - {err}')
    # 2. Check format of headings, e.g. 'Use case', 'How it works', etc.
    try:
        checker.check_format_heading()
    except Exception as err:
        count += 1
        print(f'{count}. {checker.folder_path} - {err}')
    # 3. Check format of title section, i.e. title, description and image URLs.
    try:
        checker.check_format_title_section()
    except Exception as err:
        count += 1
        print(f'{count}. {checker.folder_path} - {err}')
    # 4. Check format of relevant APIs.
    try:
        checker.check_format_apis()
    except Exception as err:
        count += 1
        print(f'{count}. {checker.folder_path} - {err}')
    # 5. Check format of tags.
    try:
        checker.check_format_tags()
    except Exception as err:
        count += 1
        print(f'{count}. {checker.folder_path} - {err}')
    # 6. Check if redundant APIs in tags
    try:
        checker.check_redundant_apis_in_tags()
    except Exception as err:
        count += 1
        print(f'{count}. {checker.folder_path} - {err}')
    return count


def single(path: str) -> None:
    """
    Run the checks against a single sample's README.

    :param path: The path to a single sample folder.
    :return: Returns nothing, throws on exceptions.
    """
    exception_count = run_check(path, 0)
    # Throw once if there are exceptions.
    if exception_count > 0:
        raise Exception('Error(s) occurred during checking a single design.')


def main():

    msg = 'README checker. Run it against a single sample folder. ' \
          'On success: Script will exit with zero. ' \
          'On failure: Style violations will print to console and the script ' \
          'will exit with non-zero code.'
    parser = argparse.ArgumentParser(description=msg)
    parser.add_argument('-s', '--single', help='path to a sample folder')
    args = parser.parse_args()
    if args.single:
        try:
            single(args.single)
        except Exception as err:
            raise err
    else:
        raise Exception('Invalid arguments, abort.')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'{error}')
        exit(1)
