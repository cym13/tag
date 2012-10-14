#!/usr/bin/env python
# tag is an utility to rename files according to a set of given tags.
# Copyright 2012 calendros
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

import sys
import os
import re
import argparse

import unittest

## @return a list containing tuples where key is a filename and value is the
# list of tags for this file.
def parse_filenames(plain_filenames):
    ret = []
    regex = re.compile('^(.*)\[([^][]+)\]\s*$')
    for fn_org in plain_filenames:
        tags = set()
        dirname = os.path.dirname(fn_org)
        fn = os.path.basename(fn_org)
        base, ext = os.path.splitext(fn)
        match = regex.search(base)
        if match is not None:
            base = match.group(1).strip()
            strtags = match.group(2).strip()
            if strtags != '':
                for tag in strtags.split(','):
                    tag = tag.strip()
                    if tag != '': tags.add(tag)
        tags = sorted(tags) # sort + back to a list
        base = base.strip()
        ret.append(((dirname, fn), (base, tags, ext)))
    return ret

## @ return a list containing tuples (filename:tag_list)
# @param filenames list of complex type filenames
def add_tag(filenames, tag):
    tag = tag.strip()
    return [(((dirname, fn), (base,
        sorted(set(tags + [tag])), # modif is here: copy + sort + uniq(set)
        ext)))
        for (dirname, fn), (base, tags, ext) in filenames]

## @ return a list containing tuples (filename:tag_list)
# @param filenames list of complex type filenames
def del_tag(filenames, tag):
    tag = tag.strip()
    ret = []
    for (dirname, fn), (base, tags, ext) in filenames:
        if tag in tags:
            #tags = tags[:] # copy before operation
            tags = sorted(set(tags)) # copy + sort + uniq
            tags.remove(tag)
        ret.append(((dirname, fn), (base, tags, ext)))
    return ret

## @return a plain filename from complex filename
def apply_tag(complex_filename):
    newfilename = ''
    (dirname, fn), (base, tags, ext) = complex_filename
    if base == '': base = ' '
    if tags:
        newfilename = base + ' [' + ', '.join(tags) + ']' + ext
    else:
        newfilename = base + ext
    return os.path.join(dirname, newfilename)

## @return unexistant plain filename (tested with os.path.exists)
def get_unexistant_filename(complex_filename):
    (dirname, fn), (base, tags, ext) = complex_filename
    limit = 100000 # arbitrary limit to prevent
    x = 1          # infinite loop if a lot of files exist
    to_fn = apply_tag(complex_filename)
    while os.path.exists(to_fn) and x <= limit:
        x += 1
        newbase = base + '~' + str(x) + '~'
        if base == '': newbase = ' ' + newbase
        complex_filename = ((dirname, fn), (newbase, tags, ext))
        to_fn = apply_tag(complex_filename)
    if x >= limit: to_fn = None # indicates an error
    return to_fn

## this function commits tags to filenames
# @return the number of errors encountered.
# @param filenames list of complex filenames
def files_rename(filenames, quiet):
    ret = 0
    for complex_filename in filenames:
        (dirname, fn), (base, tags, ext) = complex_filename
        to_fn = apply_tag(complex_filename)
        from_fn = os.path.join(dirname, fn)
        if to_fn == from_fn: continue
        if os.path.exists(to_fn):
            to_fn = get_unexistant_filename(complex_filename)
            if to_fn is None:
                ret += 1
                if not quiet:
                    print >> sys.stderr, "ERROR `%s': %s" % (
                            from_fn,
                            'same name too many times (in this form: ~num~)')
                continue
        # Note:
        # there is a race condition here if a file is created having the
        # destination filename after filename existance test and loop is
        # done.
        # but it is unlikely to happen.
        # Cases: - newfilename is a directory and OSError will be raised.
        #        - newfilename is a file and will be overwritten on linux
        #        or OSError will be raised on windows.
        try:
            os.rename(from_fn, to_fn)
        except OSError, err:
            ret += 1
            if not quiet:
                print >> sys.stderr, "ERROR `%s -> %s': %s" % (
                        from_fn, to_fn, str(err))
    if ret > 0 and not quiet:
        print >> sys.stderr, "%d errors during renaming process." % ret
    return ret

###############################################################################
# TESTS
###############################################################################

class TestMode(unittest.TestCase):
    def setUp(self):
        self.filenames = [
                'fn',
                'fn.ext',
                'filename with spaces',
                'fn trailling space ',
                'fn trailling spaces   ',
                ' fn begin with space',
                '   fn begin with spaces',
                ' begining and end spaces ',
                '  multiples start and end spaces  ',
                'filename with spaces.ext',
                'fn trailling space .ext',
                'fn trailling spaces   .ext',
                ' fn begin with space.ext',
                '   fn begin with spaces.ext',
                ' begining and end spaces .ext',
                '  multiples start and end spaces  .ext',
                '/somepath/fn',
                '/somepath/fn.ext',
                '/somepath/filename with spaces',
                '/somepath/fn trailling space ',
                '/somepath/fn trailling spaces   ',
                '/somepath/ fn begin with space',
                '/somepath/   fn begin with spaces',
                '/somepath/ begining and end spaces ',
                '/somepath/  multiples start and end spaces  ',
                '/somepath/filename with spaces.ext',
                '/somepath/fn trailling space .ext',
                '/somepath/fn trailling spaces   .ext',
                '/somepath/ fn begin with space.ext',
                '/somepath/   fn begin with spaces.ext',
                '/somepath/ begining and end spaces .ext',
                '/somepath/  multiples start and end spaces  .ext',
                ]
        self.filenames_with_tags = [
                'fn [a, a 1, a 2, a3]',
                'fn [a, a 1, a 2, a3].ext',
                'filename with spaces [a, a 1, a 2, a3]',
                'fn trailling space [a, a 1, a 2, a3]',
                'fn trailling spaces [a, a 1, a 2, a3]',
                'fn begin with space [a, a 1, a 2, a3]',
                'fn begin with spaces [a, a 1, a 2, a3]',
                'begining and end spaces [a, a 1, a 2, a3]',
                'multiples start and end spaces [a, a 1, a 2, a3]',
                'filename with spaces [a, a 1, a 2, a3].ext',
                'fn trailling space [a, a 1, a 2, a3].ext',
                'fn trailling spaces [a, a 1, a 2, a3].ext',
                'fn begin with space [a, a 1, a 2, a3].ext',
                'fn begin with spaces [a, a 1, a 2, a3].ext',
                'begining and end spaces [a, a 1, a 2, a3].ext',
                'multiples start and end spaces [a, a 1, a 2, a3].ext',
                '/somepath/fn [a, a 1, a 2, a3]',
                '/somepath/fn [a, a 1, a 2, a3].ext',
                '/somepath/filename with spaces [a, a 1, a 2, a3]',
                '/somepath/fn trailling space [a, a 1, a 2, a3]',
                '/somepath/fn trailling spaces [a, a 1, a 2, a3]',
                '/somepath/fn begin with space [a, a 1, a 2, a3]',
                '/somepath/fn begin with spaces [a, a 1, a 2, a3]',
                '/somepath/begining and end spaces [a, a 1, a 2, a3]',
                '/somepath/multiples start and end spaces [a, a 1, a 2, a3]',
                '/somepath/filename with spaces [a, a 1, a 2, a3].ext',
                '/somepath/fn trailling space [a, a 1, a 2, a3].ext',
                '/somepath/fn trailling spaces [a, a 1, a 2, a3].ext',
                '/somepath/fn begin with space [a, a 1, a 2, a3].ext',
                '/somepath/fn begin with spaces [a, a 1, a 2, a3].ext',
                '/somepath/begining and end spaces [a, a 1, a 2, a3].ext',
                '/somepath/multiples start and end spaces [a, a 1, a 2, a3].ext',
                ]
        self.complex_part_empty_tags = [
                ('fn', [], ''),
                ('fn', [], '.ext'),
                ('filename with spaces', [], ''),
                ('fn trailling space', [], ''),
                ('fn trailling spaces', [], ''),
                ('fn begin with space', [], ''),
                ('fn begin with spaces', [], ''),
                ('begining and end spaces', [], ''),
                ('multiples start and end spaces', [], ''),
                ('filename with spaces', [], '.ext'),
                ('fn trailling space', [], '.ext'),
                ('fn trailling spaces', [], '.ext'),
                ('fn begin with space', [], '.ext'),
                ('fn begin with spaces', [], '.ext'),
                ('begining and end spaces', [], '.ext'),
                ('multiples start and end spaces', [], '.ext'),
                ('fn', [], ''),
                ('fn', [], '.ext'),
                ('filename with spaces', [], ''),
                ('fn trailling space', [], ''),
                ('fn trailling spaces', [], ''),
                ('fn begin with space', [], ''),
                ('fn begin with spaces', [], ''),
                ('begining and end spaces', [], ''),
                ('multiples start and end spaces', [], ''),
                ('filename with spaces', [], '.ext'),
                ('fn trailling space', [], '.ext'),
                ('fn trailling spaces', [], '.ext'),
                ('fn begin with space', [], '.ext'),
                ('fn begin with spaces', [], '.ext'),
                ('begining and end spaces', [], '.ext'),
                ('multiples start and end spaces', [], '.ext'),
                ]
        self.complex_part_tags = [
                ('fn', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('filename with spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn trailling space', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn trailling spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn begin with space', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn begin with spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('begining and end spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('multiples start and end spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('filename with spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn trailling space', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn trailling spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn begin with space', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn begin with spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('begining and end spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('multiples start and end spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('filename with spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn trailling space', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn trailling spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn begin with space', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('fn begin with spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('begining and end spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('multiples start and end spaces', ['a', 'a 1', 'a 2', 'a3'], ''),
                ('filename with spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn trailling space', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn trailling spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn begin with space', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('fn begin with spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('begining and end spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ('multiples start and end spaces', ['a', 'a 1', 'a 2', 'a3'], '.ext'),
                ]
        self.complex_part_a_and_a2_tags = [
                ('fn', ['a', 'a 2'], ''),
                ('fn', ['a', 'a 2'], '.ext'),
                ('filename with spaces', ['a', 'a 2'], ''),
                ('fn trailling space', ['a', 'a 2'], ''),
                ('fn trailling spaces', ['a', 'a 2'], ''),
                ('fn begin with space', ['a', 'a 2'], ''),
                ('fn begin with spaces', ['a', 'a 2'], ''),
                ('begining and end spaces', ['a', 'a 2'], ''),
                ('multiples start and end spaces', ['a', 'a 2'], ''),
                ('filename with spaces', ['a', 'a 2'], '.ext'),
                ('fn trailling space', ['a', 'a 2'], '.ext'),
                ('fn trailling spaces', ['a', 'a 2'], '.ext'),
                ('fn begin with space', ['a', 'a 2'], '.ext'),
                ('fn begin with spaces', ['a', 'a 2'], '.ext'),
                ('begining and end spaces', ['a', 'a 2'], '.ext'),
                ('multiples start and end spaces', ['a', 'a 2'], '.ext'),
                ('fn', ['a', 'a 2'], ''),
                ('fn', ['a', 'a 2'], '.ext'),
                ('filename with spaces', ['a', 'a 2'], ''),
                ('fn trailling space', ['a', 'a 2'], ''),
                ('fn trailling spaces', ['a', 'a 2'], ''),
                ('fn begin with space', ['a', 'a 2'], ''),
                ('fn begin with spaces', ['a', 'a 2'], ''),
                ('begining and end spaces', ['a', 'a 2'], ''),
                ('multiples start and end spaces', ['a', 'a 2'], ''),
                ('filename with spaces', ['a', 'a 2'], '.ext'),
                ('fn trailling space', ['a', 'a 2'], '.ext'),
                ('fn trailling spaces', ['a', 'a 2'], '.ext'),
                ('fn begin with space', ['a', 'a 2'], '.ext'),
                ('fn begin with spaces', ['a', 'a 2'], '.ext'),
                ('begining and end spaces', ['a', 'a 2'], '.ext'),
                ('multiples start and end spaces', ['a', 'a 2'], '.ext'),
                ]
        #self.complex_filenames_with_tags_stripped_and_fn_has_tags = [
        #        ((dirname, fn.strip()), (base, tags, ext))
        #        for (dirname, fn), (base, tags, ext) in
        #        self.complex_filenames_with_tags
        #        ]

    def test_good_setup(self):
        self.assertEqual(len(self.filenames),
                len(self.filenames_with_tags))
        self.assertEqual(len(self.filenames),
                len(self.complex_part_empty_tags))
        self.assertEqual(len(self.filenames),
                len(self.complex_part_tags))
        self.assertEqual(len(self.filenames),
                len(self.complex_part_a_and_a2_tags))

    def test_parse_filenames_empty(self):
        complex_filenames = parse_filenames(self.filenames)
        self.assertEqual(len(complex_filenames), len(self.filenames))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_empty_tags[i])

    def test_parse_filenames_with_tags(self):
        complex_filenames = parse_filenames(self.filenames_with_tags)
        self.assertEqual(len(complex_filenames), len(self.filenames))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames_with_tags[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_tags[i])

    def test_add_tag_both_lists(self):
        complex_filenames = parse_filenames(self.filenames)
        complex_filenames2 = parse_filenames(self.filenames_with_tags)
        tags = [
                'a 1',
                'a',
                'a3',
                ' a 2 ',
                ]
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames))
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames2), len(self.filenames))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames[i])
            filename = os.path.join(complex_filenames2[i][0][0],
                                    complex_filenames2[i][0][1])
            self.assertEqual(filename, self.filenames_with_tags[i])
            self.assertEqual(complex_filenames[i][1],
                    complex_filenames2[i][1])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_tags[i])
        self.assertNotEqual(complex_filenames, complex_filenames2)

    def test_add_tag_middle(self):
        complex_filenames = parse_filenames(self.filenames)
        tags = [
                'a',
                ' a 2 ',
                ]
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_a_and_a2_tags[i])
        tags = [
                'a 1',
                'a3',
                ]
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_tags[i])
        tags = [
                'a 1',
                'a',
                'a3',
                ' a 2 ',
                ]
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_tags[i])


    def test_del_tag_partial_and_continue(self):
        tags = [
                'unexist',
                ' unexist ',
                '  test  ',
                'test2',
                'test 3',
                ' test 4 ',
                '  a 1  ',
                'a3',
                '     a   2',
                ]
        complex_filenames = parse_filenames(self.filenames_with_tags)
        for tag in tags:
            complex_filenames = del_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames_with_tags))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames_with_tags[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_a_and_a2_tags[i])
        tags = ['a', 'a 2']
        for tag in tags:
            complex_filenames = del_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames_with_tags))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames_with_tags[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_empty_tags[i])

    def test_del_tag_full(self):
        tags = [
                'unexist',
                ' unexist ',
                '  test  ',
                'test2',
                'test 3',
                ' test 4 ',
                '  a 1  ',
                'a3',
                '     a   2',
                'a 2   ',
                '   a'
                ]
        complex_filenames = parse_filenames(self.filenames_with_tags)
        for tag in tags:
            complex_filenames = del_tag(complex_filenames, tag)
        self.assertEqual(len(complex_filenames), len(self.filenames_with_tags))
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames_with_tags[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_empty_tags[i])

    def test_add_and_del(self):
        tags = [
                'unexist',
                ' unexist ',
                '  test  ',
                'test2',
                'test 3',
                ' test 4 ',
                '  a 1  ',
                'a3',
                '     a   2',
                'a 2   ',
                '   a'
                ]
        complex_filenames = parse_filenames(self.filenames)
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        for tag in tags:
            complex_filenames = del_tag(complex_filenames, tag)
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_empty_tags[i])

        complex_filenames = parse_filenames(self.filenames_with_tags)
        for tag in tags:
            complex_filenames = add_tag(complex_filenames, tag)
        for tag in tags:
            complex_filenames = del_tag(complex_filenames, tag)
        for i in range(len(complex_filenames)):
            filename = os.path.join(complex_filenames[i][0][0],
                                    complex_filenames[i][0][1])
            self.assertEqual(filename, self.filenames_with_tags[i])
            self.assertEqual(complex_filenames[i][1],
                self.complex_part_empty_tags[i])


###############################################################################
# MAIN
###############################################################################

if __name__ == '__main__':
    #unittest.main()
    #raise SystemExit
    parser = argparse.ArgumentParser(description =
            'Manage tags by filenames.')
    parser.add_argument('filenames', metavar = 'file', nargs = '+',
            help = 'file to rename according to tag operations')
    parser.add_argument('-a', '--add', metavar = 'tag', action = 'append',
            help = 'append tag to filenames')
    parser.add_argument('-d', '--delete', metavar = 'tag', action = 'append',
            help = 'remove tag from filenames')
    parser.add_argument('-n', '--normalize', action = 'store_true',
            help = 'rename files sorting tags and trimming spaces')
    parser.add_argument('-q', '--quiet', action = 'store_true',
            help = 'print nothing on standard output')
    #parser.add_argument('-t', '--testmode', action = 'store_true',
    #        help = 'for developers only')
    args = parser.parse_args()
    if args.add is None and args.delete is None and not args.normalize:
        parser.print_usage()
        print >> sys.stderr, 'error: no action to do'
        raise sys.exit(1)
    filenames = parse_filenames(args.filenames)
    if args.add:
        for tag in args.add:
            for tag2 in tag.split(','):
                tag2 = tag2.strip()
                filenames = add_tag(filenames, tag2)
    if args.delete:
        for tag in args.delete:
            for tag2 in tag.split(','):
                tag2 = tag2.strip()
                filenames = del_tag(filenames, tag2)
    #print str(filenames)
    errors = files_rename(filenames, args.quiet)
    if errors > 0:
        sys.exit(1)
        #if errors < 100:
        #    sys.exit(errors)
        #else:
        #    sys.exit(100)
