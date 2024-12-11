```
// index of utf8 code point at pos
static int utfpos(const char* s, int pos) {
int i = 0;
for (int n = 0; pos >= 0 && s && s[i]; i++) {
    n += (s[i] & 192) != 128;
    if (n == pos + 1) {
        return i;
    }
}
return i;
}
```

// scan string for width and lines
static struct text scan\_str(const char\* str) {
    const char\* s = str ? str : "";
    struct text t = {
        .width = 0,
        .lines = (s\[0\] != 0),
    };
    int width = 0;
    for (t.size = 0; s\[t.size\]; t.size++) {
        char ch      = s\[t.size\];
        int  newline = (ch == '\\n');
        width = newline ? 0 : width;
        width += (ch & 192) != 128 && (uint8\_t)ch > 31;
        t.lines += newline;
        t.width = MAX(t.width, width);
    }
    return t;
}

// iterate through lines, false when end is reached
static bool next\_line(struct line\* l) {
    if (!l->str || !l->str\[0\]) {
        return false;
    }
    l->line  = l->str;
    l->size  = 0;
    l->width = 0;
    for (const char\* s = l->str; s\[0\] && s\[0\] != '\\n'; s++) {
        l->size  += 1;
        l->width += (s\[0\] & 192) != 128 && (uint8\_t)s\[0\] > 31;
    }
    l->str += l->size + !!l->str\[l->size\];
    return true;
}

// true if utf8 code point could be wide
static bool is\_wide\_perhaps(const uint8\_t\* s, int n) {
    // Character width depends on character, terminal and font. There is no
    // reliable method, however most frequently used characters are narrow.
    // Zero with characters are ignored, and hope that user input is benign.
    if (n < 3 || s\[0\] < 225) {
        // u+0000 - u+1000, basic latin - tibetan
        return false;
    } else if (s\[0\] == 226 && s\[1\] >= 148 && s\[1\] < 152) {
        // u+2500 - u+2600 box drawing, block elements, geometric shapes
        return false;
    }
    return true;
}

# NAME

Cancer - I'm afraid it's terminal...

# SYNOPSIS

```perl
use Cancer;
...;
```

# DESCRIPTION

Rich console stuff

# See Also

TODO

# LICENSE

This software is Copyright (c) 2024 by Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

See the `LICENSE` file for full text.

# AUTHOR

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 548:

    Unknown directive: =c
