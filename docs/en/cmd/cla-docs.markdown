---
title: cla docs - Help and Documentation Generation
index: 5000
icon: console
---

`cla docs-export`: Exports the help docs into a Mkdocs static site.

**Note**: For this command to work, you need to install Mkdocs, which
in turn requires Python.

Options:

#### --doc-lang en|es

The language site to export.

#### --mkdocs-path dir

The path to the folder where the
temporary Mkdocs site will be created.

**Warning**: everytime this command executes, the
mkdocs folder is completely deleted before being written to.

#### --site-dir dir

The final destination site.

If no dir is specified, the documentation
static site will be created under
`/static/mkdocs` in your Clarive server.

