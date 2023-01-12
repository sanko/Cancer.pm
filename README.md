[![Actions Status](https://github.com/sanko/Cancer.pm/actions/workflows/ci.yaml/badge.svg)](https://github.com/sanko/Cancer.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Cancer.svg)](https://metacpan.org/release/Cancer)
# NAME

Cancer - It's Terminal

# SYNOPSIS

```perl
use Cancer;
```

# DESCRIPTION

Cancer is a text-based UI library inspired by
[termbox-go](https://github.com/nsf/termbox-go). Use it to create
[TUI](https://en.wikipedia.org/wiki/Text-based_user_interface) in pure perl.

# Functions

Cancer is needlessly object oriented so you'll need the following constructor
first...

## `new( [...] )`

```perl
my $term = Cancer->new( '/dev/ttyS06' ); # Don't do this
```

Creates a new Cancer object.

The optional parameter is the tty you'd like to bind to and defaults to
`/dev/tty`.

All setup is automatically done for your platform. This constructor will croak
on failure (such as not being in a supported terminal).

## `hide_cursor( )`

## `show_cursor( )`

## `mouse( [...] )`

```perl
    $term->mouse;
```

Returns a boolean value. True if the mouse is enabled.

```perl
    $term->mouse( 1 );
```

Enable the mouse.

```perl
    $term->mouse( 0 );
```

Disable the mouse.

## `cls( )`

Immediatly clears the screen.

## `render( )`

Syncronizes the internal back buffer with the terminal. ...it makes things show
up on screen.

## `title( $title )`

Immediatly sets the terminal's title.

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2020-2023 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See
http://www.perlfoundation.org/artistic\_license\_2\_0.  For clarification, see
http://www.perlfoundation.org/artistic\_2\_0\_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.
