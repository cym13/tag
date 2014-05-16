Description
===========

Manages tags by filenames in the following form:

    filename[tag][tag_without_space][tag with spaces].extension

Features
========

- The tag is contained in the file name.
- Tag multiple files or directories at once.
- Add or delete multiple tags at once.
- Made in Python.

Dependencies
============

docopt     https://github.com/docopt/docopt or "pip install docopt"

Installation
============

To install tag, just copy it into your PATH somewhere and make sure that
docopt is installed as well.

For example you can copy the executable file named tag in your home, in the
directory ~/bin and add `export PATH=~/bin:$PATH` in your ~/.bashrc.

And to install the manpage in a location where man can find it, you can copy
it in a man/man1 subdirectory of any part of your path (it works like this in
my own system which is under ubuntu and I hope it will work as well on yours).

    mkdir -p ~/bin/man/man1 && cp tag.1 ~/bin/man/man1/.

To generate fresh documentation you can use pandoc:

    pandoc -s -w man tag.1.md -o tag.1

Rationale
=========

The best point in using Tag is the fact that the tag is directely inserted in
the filenames. The database managing tags is directly self-contained in the
filesytem and consequently is rock-solid and futur-proof. Moreover it allows
the use of any standard unix utilities for querying tags. And you gain the
ability to see directly tags whatever the program you use to interact with
files.

Its command-line being allows the user to use Tag in scripts AND it respects
the unix philosophy combining mulitple simple utilities doing no more than
their job but doing it well.

TODO
====

- Write unitests
- Compile the man page

License
=======

GNU General Public License version 3 or later.

Check `gpl-3.0.txt` for the full license text.

Authors
=======

Calendros
Rewritten by Cédric Picard

Feel free to ask any question or suggestion or just thanking to
calendros-dev [at] laposte [dot] net
or
cedric.picard [at] efrei [dot] net

Further reading
===============

See also the tag(1) man page.

