# Reason for splitting the files

The localization has been restructured for simplifying maintenance.
Per theme there is one directory containing the dictionaries.
The structure of the files per directory is intended to be identical facilitating comparison and translation.

A missing translation start with a comment symbol (`#`).
Real comments start with two comment symbols (`##Comment`).

# Translating

If possible do not only look for missing entries marked with `#` but also check the existing ones.
It is possible that some still contain English translations.

...and do not forget to remove the comment symbols after translating.

# Adding a new key

When adding a new key, it should be added to all files in the same line.
For language files without an immediate translation, create a comment (`#NEW_KEY   =`).
This makes it immediately clear that a translation is still missing.

Using spaces instead of tabs and aligning the entries within a block improves readability.

# Moving or removing a key

Again, change all language files at the same time, so the structure of the files for a theme remains identical.