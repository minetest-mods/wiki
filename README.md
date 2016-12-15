
Wiki Mod
========

Another random mod by me.

This mod provides a "Wiki" block. You can create and edit wiki pages with it.

The pages are saved as `<worldpath>/wiki/<pagename>`. All spaces in the page
name are converted to underscores, and all other characters not in
`[A-Za-z0-9-]` are converted to hex notation `%XX`.

The text can contain hyperlinks in the form of `[link text]` to other pages.
Such links are added at the right of the form.

You can craft a "Wiki block" by putting 9 bookshelves in the crafting grid.

Only players with the `wiki` priv can create/edit pages.


## Installing

Install by following the instructions in the [Installing mods][install]
article on the Minetest wiki, then add `wiki` to the `secure.trusted_mods`
setting in `minetest.conf`.

[install]: https://wiki.minetest.net/Installing_mods


## License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
