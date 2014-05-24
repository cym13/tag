#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# tag is an utility to rename files according to a set of given tags.
# Copyright 2012 calendros
# Copyright 2014 Cédric Picard
#
# LICENSE
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# END_OF_LICENSE
"""
Manage tags by filenames.

Usage: tag [-h] [-a tag] [-d tag] [-l] [-n] FILE...

Arguments:
  file                  file to rename according to tag operations

Options:
  -h, --help            show this help message and exit
  -a, --add tag         append tag to filenames
  -d --delete tag       remove tag from filenames
  -l, --list            list tags from filenames
  -n, --normalize       rename files sorting tags and trimming spaces
"""

import sys
import os
import re
from docopt import docopt
from functools import partial


def tags(filename):
    """
    Returns the list of tags in `filename'.
    """
    return [x for x in bsplit(filename) if exists(x, filename)]


def add(filename, tag):
    """
    Returns the new name (path) of `filename' with `tag' added.
    """
    if exists(tag, filename):
        return filename

    parts = bsplit(filename)

    if len(parts) == 1 and '.' in parts[0]:
        parts = filename.split(".")
        return "%s[%s].%s" % (parts[0], tag, parts[1])

    if '.' not in parts[-1]:
        parts.append(tag)
        return parts[0] + ''.join("[%s]" % x for x in parts[1:])

    parts.insert(-1, tag)
    return parts[0] + ''.join("[%s]" % x for x in parts[1:-1]) + parts[-1]


def delete(filename, tag):
    """
    Returns the new name (path) of `filename' with `tag' deleted.
    """
    return filename.replace("[%s]" % tag, "")


def normalize(filename):
    """
    Returns the new name (path) of `filename' with sorted and trimmed tags.
    """
    ftags = [x.strip() for x in tags(filename)]
    ftags.sort()

    fn = filename
    for tag in ftags:
        fn = add(delete(fn, tag), tag)

    return fn


def exists(tag, filename):
    """
    Returns wether `tag' is in `filename' or not.
    """
    return "[" + tag + "]" in filename


def bsplit(string):
    """
    Splits `string' on opening and closing brackets.
    Returns a list.
    """
    result = []
    for opb in string.split("["):
        for clb in opb.split("]"):
            if clb != "":
                result.append(clb)

    return result


def main():
    args = docopt(__doc__)

    for fn in args["FILE"]:
        new_fn = fn
        if args["--list"]:
            print('\n'.join(tags(fn)))

        elif args["--add"]:
            for tag in args["--add"].split(","):
                new_fn = add(new_fn, tag)

        elif args["--delete"]:
            for tag in args["--delete"].split(","):
                new_fn = delete(new_fn, tag)

        elif args["--normalize"]:
            new_fn = normalize(new_fn)

        os.rename(fn, new_fn)


if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, PermissionError) as e:
        sys.exit(e)
