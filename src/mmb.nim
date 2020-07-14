import times, os, json, parsecfg, asyncdispatch
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

when isMainModule:
  let timeStart = now()
  var content: JsonNode = newJObject()
  var config = loadConfig("config.ini")
  let basePath = config.getSectionValue("", "basePath")

  let hg = newHtmlGenerator(config)
  let fg = newFeedGenerator(config)

  content["blog_title"] = %* config.getSectionValue("general", "blogName")
  content["blog_url"] = %* config.getSectionValue("general", "blogUrl")
  content["blog_description"] = %* config.getSectionValue("general", "blogDescription")
  content["last_published"] = %* now().utc.format("ddd', 'd MMM yyyy HH:mm:ss 'GMT'")
  content["articles"] = hg.walkContent(basePath & '/' & config.getSectionValue("", "contentPath"))
  
  echo "Building: HTML"
  hg.generateIndexHtml(content)

  echo "Building: Feeds"
  fg.makeFeeds(content)

  let timeEnd = now()
  echo "Built site in: ", (timeEnd - timeStart).inMilliseconds, "ms"
