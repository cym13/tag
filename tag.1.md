% TAG(1) Tag user manual
% Written by Calendros, and Cédric Picard
% 2012-10-14

NAME
====

tag - tag files.

SYNOPSIS
========

**tag** [**-h**] [**-a** *TAG*] [**-d** *TAG*] [**-n**] [**-q**] *FILE* [*FILE*]...

DESCRIPTION
===========

Manages tags by filenames in the form:

\ \ \ \ *filename*[*tag*][*tag_without_space*][*tag with spaces*].*extension*

Each operation on tags automatically normalize the filenames.

Beware that the space characters is sorted before alphanumerical characters.

Long options may take an `=' sign.

OPTIONS
=======

*FILE*
:    file to rename according to tag operations

**-h**\, **--help**
:    show usage and exit

**-a** *TAG*\, **--add** *TAG*
:    append *TAG* to filenames

**-d** *TAG*\, **--delete** *TAG*
:    remove *TAG* from filenames

**-n**\, **--normalize**
:    rename files sorting tags and trimming spaces

**-q**\, **--quiet**
:    print nothing on standard output

**-l**\, **--list**
:    list tags from filenames


EXEMPLES
========

Add a tag to multiple files\
\ \ **tag -a unseen film1.mkv film2.mkv** \
\ \ \ >> film1[unseen].mkv \
\ \ \ >> film2[unseen].mkv \
 \

\ \ **tag -a sametag,sametag "film1[unseen].mkv"** \
\ \ \ >> film1[sametag][unseen].mkv \
 \


Deletting two tags from a file\
\ \ **tag -d tag1,"tag  2" "file[tag  2][tag1][tag 3].ext"**\
\ \ \ >> file[tag 3].ext\
 \

\ \ **tag -d "tag1, tag  2,tag  3" "file[tag  2][tag1][tag 3].ext"**\
\ \ \ >> file.ext\
 \

Normalize a file\
\ \ **tag -n "a file[ d][b][  e  ][ b][ c  ].ext"**\
\ \ \ >> "a file[b, c, d, e].ext"

LICENSING
=========

Tag was written by Calendros and is distributed under the GPLv3.\
See file **gpl-3.0.txt** for the full license text.

REPORTING BUGS
==============

For any bug, question or suggestion about Tag please don't hesitate to send a
mail to:\
\ \ \ \ **calendros-dev** [at] **laposte** [dot] **net**

