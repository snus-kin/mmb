import times, os, json, parsecfg, asyncdispatch, strutils
import cligen
import html_generation, feeds, parsing


proc walkContent(hg: htmlGenerator, directory: string): JsonNode =
  let articles = newJArray()
  # now we do the walking
  for kind, file in walkDir(directory):
    if kind == pcFile:
      let article = parseArticle(file)

      # this could be better
      article["metadata"]["published"] = %* parseTime(
          article["metadata"]["published"].getStr,
          "yyyy-mm-dd", 
          utc())
          .format("ddd', 'd MMM yyyy HH:mm:ss 'GMT'")

      articles.add article
      # perhaps parse the date here to RFC
      # generate a html file at each node
      asyncCheck hg.generateArticleHtml(article)

  return articles

proc publish(configFile="config.ini", outputPath=""): void =
  let timeStart = now()
  var config = loadConfig(configFile)
  let basePath = config.getSectionValue("", "basePath")
 
  if outputPath != "":
    config.setSectionKey("", "outputPath", outputPath)
  else:
    let cOutputPath = config.getSectionValue("", "outputPath")
    if cOutputPath != "":
      config.setSectionKey("", "outputPath", basePath / cOutputPath)
    else:
      stderr.writeLine("ERROR: 'outputPath' value not set in config.ini")
      quit(1)

  config.setSectionKey("", "templatePath", basePath / config.getSectionValue("", "templatePath"))

  var content: JsonNode = newJObject()
  let hg = newHtmlGenerator(config)
  let fg = newFeedGenerator(config)

  content["blog_title"] = %* config.getSectionValue("general", "blogName")
  content["blog_url"] = %* config.getSectionValue("general", "blogUrl")
  content["blog_description"] = %* config.getSectionValue("general", "blogDescription")
  content["last_published"] = %* now().utc.format("ddd', 'd MMM yyyy HH:mm:ss 'GMT'")
  content["articles"] = hg.walkContent(basePath / config.getSectionValue("", "contentPath"))

  fg.makeFeeds(content)
  hg.generateIndexHtml(content)

  let timeEnd = now()
  echo "Built site in: ", (timeEnd - timeStart).inMilliseconds, "ms"

proc postTemplate(configFile="config.ini", title="", description="", author="", slug="", published=now().format("yyyy-mm-dd")): void =
  ## Creates a template blog post for you, could be used for scripting etc.
  var config = loadConfig(configFile)
  let metadata = %* {"title":title, 
                     "description":description,
                     "author":author,
                     "slug":slug,
                     "published":published}
  
  writeFile(title.addFileExt "md", pretty metadata)

when isMainModule:
  dispatchMulti([publish], [postTemplate]) 
