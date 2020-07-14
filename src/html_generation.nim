import os, json, parsecfg
import moustachu
type 
  htmlGenerator* = ref object of RootObj
    basePath: string
    templatePath: string
    outputPath: string
    templateSelected: string
    staticFiles: JsonNode

proc newHtmlGenerator*(config: Config): htmlGenerator =
  let basePath = config.getSectionValue("", "basePath") & '/'
  let templatePath = basePath & config.getSectionValue("", "templatePath") & '/'
  var hg = htmlGenerator(
    basePath: basePath,
    templatePath: templatePath,
    outputPath: basePath & config.getSectionValue("","outputPath"),
    templateSelected: templatePath & config.getSectionValue("feel", "theme")
  )

  if hg.outputPath != hg.basePath:
    removeDir(hg.outputPath)
  else:
    # output path must be set in config
    stderr.writeLine("ERROR: 'outputPath' value not set in config.ini")
    quit(1)

  let staticDirectory = hg.templateSelected & "/static"
  # copy to the output dir so we're not using the templated styles
  copyDir(staticDirectory, hg.outputPath & "/static")
  let staticFiles = newJObject()
  for kind, file in walkDir(hg.outputPath & "/static", relative=true):
    if kind == pcFile:
      let filename = splitFile(file).name
      staticFiles[filename] = %* ("static/" & file)
  hg.staticFiles = staticFiles

  return hg

proc renderArticle(hg: htmlGenerator, article: JsonNode): string =
  ## procedure to generate an article given the json info
  let tmp = readFile(hg.templateSelected & "/article.moustachu")
  article["static"] = hg.staticFiles
  var context = newContext(article)
  let rendered_file = render(tmp, context)
  return rendered_file

proc generateArticleHtml*(hg: htmlGenerator, article: JsonNode): void =
  ## This procedure generates an article html file given a json node
  let rendered_file = hg.renderArticle(article)

  # write to a user-defined slug TODO see what happens on conflict 
  let slug = '/' & article["metadata"]["slug"].getStr
  writeFile(hg.outputPath & slug, rendered_file)

proc renderIndex(hg: htmlGenerator, articles: JsonNode): string =
  ## Given a JsonNode, render an index page with a template
  let tmp = readFile(hg.templateSelected & "/index.moustachu")
  var context = newContext(articles)
  let rendered_file = render(tmp, context)
  return rendered_file

proc generateIndexHtml*(hg: htmlGenerator, articles: JsonNode): void =
  ## Given a JsonNode, generate an index page html and write it
  ## Later this could paginate, it would just slice the json up
  articles["static"] = hg.staticFiles
  let rendered_file = hg.renderIndex(articles)
  writeFile(hg.outputPath & "/index.html", rendered_file)
