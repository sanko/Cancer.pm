[![Build Status](https://travis-ci.com/sanko/Cancer.pm.svg?branch=master)](https://travis-ci.com/sanko/Cancer.pm) [![MetaCPAN Release](https://badge.fury.io/pl/Cancer.svg)](https://metacpan.org/release/Cancer)
## `hide_cursor( )`

## `show_cursor( )`

## `mouse( [...] )`

        $term->mouse;

Returns a boolean value. True if the mouse is enabled.

        $term->mouse( 1 );

Enable the mouse.

        $term->mouse( 0 );

Disable the mouse.

## `cls( )`

Immediatly clears the screen.

## `render( )`

Syncronizes the internal back buffer with the terminal. ...it makes things show up on screen.

## `title( $title )`

Immediatly sets the terminal's title.

# NAME

Cancer - Terminal UI Toolkit

# SYNOPSIS

    use Cancer;

# DESCRIPTION

Cancer is ...

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 541:

    &#x3d;cut found outside a pod block.  Skipping to next block.

- Around line 634:

    &#x3d;cut found outside a pod block.  Skipping to next block.
