import os, json
import moustachu
import markdown

let basePath = getCurrentDir() & "/env"
let templatePath = basePath & "/templates"
let outputPath = basePath & "/output"
let templateSelected = templatePath & "/default"

proc parseArticle(file: string): JsonNode =
  ## Procedure to parse markdown from a single file
  ##
  ## Markdown files are prefaced with a json object that
  ## embeds metadata such as title, date etc.
  ##
  ## This returns a json node that contains the metadata of an article
  ## and the content itself, this can then be used to create a context 
  ## for Moustache
  let articleFile = readFile(basePath & "/content/" & file)

  # The header metadata of this file is wrapped in '{' and '}' so we find the index
  # of the first '{' and the first '}' and assume that to be the header,
  # creating a new substring
  let headerStart = articleFile.find('{')
  let headerEnd = articleFile.find('}')
  let header = articleFile[headerStart .. headerEnd]

  let article = parseJson("{}")

  # now parse the file itself
  try:
    article["metadata"] = parseJson(header)
    article["content"] = %* markdown(articleFile[headerEnd+1 ..< len(articleFile)])
    return article
  except JsonParsingError:
    stderr.writeLine("ERROR File: " & file & " has a malformed header")
    quit(1)
  except MarkdownError:
    stderr.writeLine("ERROR File: " & file & " markdown parsing error")
    quit(1)
  raise newException(ValueError, "Some unspecified parsing error occured")

proc renderArticle(article: JsonNode): string = 
  ## Procedure to render an article given the json information
  let baseTemplate = readFile(templateSelected & "/article.moustachu")
  # here's where we parse the markdown file into a context
  var context = newContext(article)
  let rendered_file = render(baseTemplate, context)
  return rendered_file

proc generateHtmlFiles*(): void =
  ## TODO loop over whole content folder
  ## slugs and categories
  ## This procedure generate html files using the templates defined in the selected theme
  let article = parseArticle("test.md")
  let rendered_file = renderArticle(article)

  # write to a user-defined slug TODO see what happens on conflict 
  let slug = '/' & article["metadata"]["slug"].getStr & ".html"
  writeFile(outputPath & slug, rendered_file)
