import os, json
import moustachu

let basePath = getCurrentDir() & "/env"
let templatePath = basePath & "/templates"
let outputPath = basePath & "/output"
let templateSelected = templatePath & "/default"

proc renderArticle(article: JsonNode): string = 
  ## Procedure to render an article given the json information
  let baseTemplate = readFile(templateSelected & "/article.moustachu")
  # here's where we parse the markdown file into a context
  var context = newContext(article)
  let rendered_file = render(baseTemplate, context)
  return rendered_file

proc generateArticleHtml*(article: JsonNode): void =
  ## This procedure generates an article html file given a json node
  let rendered_file = renderArticle(article)

  # write to a user-defined slug TODO see what happens on conflict 
  let slug = '/' & article["metadata"]["slug"].getStr & ".html"
  writeFile(outputPath & slug, rendered_file)
