import os, json
import moustachu
let basePath = getCurrentDir() & "/env"
let templatePath = basePath & "/templates"
let outputPath = basePath & "/output"
# this could be extended to theme in a config file easily
let templateSelected = templatePath & "/snufk.in"
# make sure that we dont have any orphan non-generated files in the output
removeDir(outputPath)

let staticDirectory = templateSelected & "/static"
# copy to the output dir so we're not using the templated styles
copyDir(staticDirectory, outputPath & "/static")
let staticFiles = newJObject()
for kind, file in walkDir(outputPath & "/static", relative=true):
  if kind == pcFile:
    let filename = splitFile(file).name
    staticFiles[filename] = %* ("static/" & file)


proc renderArticle(article: JsonNode): string = 
  ## Procedure to render an article given the json information
  let tmp = readFile(templateSelected & "/article.moustachu")
  article["static"] = staticFiles
  echo pretty(article)
  var context = newContext(article)
  let rendered_file = render(tmp, context)
  return rendered_file

proc generateArticleHtml*(article: JsonNode): void =
  ## This procedure generates an article html file given a json node
  let rendered_file = renderArticle(article)

  # write to a user-defined slug TODO see what happens on conflict 
  let slug = '/' & article["metadata"]["slug"].getStr
  writeFile(outputPath & slug, rendered_file)

proc renderIndex(articles: JsonNode): string =
  ## Given a JsonNode, render an index page with a template
  let tmp = readFile(templateSelected & "/index.moustachu")
  var context = newContext(articles)
  let rendered_file = render(tmp, context)
  return rendered_file

proc generateIndexHtml*(articles: JsonNode): void =
  ## Given a JsonNode, generate an index page html and write it
  ## Later this could paginate, it would just slice the json up
  articles["static"] = staticFiles
  let rendered_file = renderIndex(articles)
  writeFile(outputPath & "/index.html", rendered_file)
