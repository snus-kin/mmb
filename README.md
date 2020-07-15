# Make My Blog
`mmb` is a simple static site generator with lots of extensibility and simple
templating. 

## Features
`mmb publish`

Convert markdown files in the `contentPath` to html files in the `outputPath`
creating feeds and index pages. All of the blog is represented as a json tree
so is structured and portable.

Config for RSS, Atom, json Tree

`mmb template -t title`

Creates a template blog at `contentPath/title.md` ready for writing in.
