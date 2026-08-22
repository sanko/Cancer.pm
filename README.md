# NAME

Cancer - I'm afraid it's terminal...

# SYNOPSIS

```perl
use Cancer;
...;
```

# DESCRIPTION

Cancer is a collection of modules for building rich text terminal user
interfaces: ANSI-aware string processing, color blending, cell buffers, and a
Perl port of [Charm Lipgloss](https://github.com/charmbracelet/lipgloss).

The distribution is organized around these packages:

- [Cancer::Lipgloss](https://metacpan.org/pod/Cancer%3A%3ALipgloss) - styles, borders, layout, and compositing.
- [Cancer::CellBuf::Writer](https://metacpan.org/pod/Cancer%3A%3ACellBuf%3A%3AWriter) - cell buffer rendering and downsampling.
- [Cancer::Color::Blend](https://metacpan.org/pod/Cancer%3A%3AColor%3A%3ABlend) - color space math (CIELAB, HSL, HSV).
- [Cancer::CharmTone](https://metacpan.org/pod/Cancer%3A%3ACharmTone) - the CharmTone color palette as constants.

This top level module declares the namespace and currently serves little more
purpose than existing loudly.

# SEE ALSO

[Cancer::Lipgloss](https://metacpan.org/pod/Cancer%3A%3ALipgloss)

# LICENSE

This software is Copyright (c) 2026 by Sanko Robinson.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

See the `LICENSE` file for full text.

# AUTHOR

Sanko Robinson  [https://github.com/sanko](https://github.com/sanko)
