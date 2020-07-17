import times, os, json, parsecfg, asyncdispatch
import cligen
import htmlgen, feeds, parsing


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
      # generate a html file at each node
      asyncCheck hg.generateArticleHtml(article)

  return articles

proc deleteUnused(config: Config, content: JsonNode) {.async.} = 
  # maybe this can be a proc input config and content
  var articleSlugs: seq[string]
  for article in content["articles"]:
    articleSlugs.add article["metadata"]["slug"].getStr
    if article["metadata"]["slug"].getStr in articleSlugs:
      stderr.writeLine("WARNING: Duplicate slug in file " & article["metadata"]["title"].getStr)

  # here we would also get images ? or at least just copy them  maybe a proc

  # Now delete any files that aren't in the blog json node
  for kind, file in walkDir(config.getSectionValue("","outputPath")):
    # only files, not directories
    if kind == pcFile:
      # delete article if not in list of article slugs
      let split = file.splitFile
      if split[1] & split[2] notin articleSlugs and split[2] == ".html":
        removeFile(file)
      # here we would delete image if not in list of images

proc publish(configFile="config.ini", outputPath=""): void =
  ## Build html files and feeds, publish to an output path
  let timeStart = now()
  var config = loadConfig(configFile)
  let basePath = config.getSectionValue("", "basePath")

  # Make sure the output path is set so we don't spew files everywhere
  if outputPath != "":
    config.setSectionKey("", "outputPath", outputPath)
  else:
    let cOutputPath = config.getSectionValue("", "outputPath")
    if cOutputPath != "":
      config.setSectionKey("", "outputPath", basePath / cOutputPath)
    else:
      echo "WARNING: outputPath not set in: " & configFile
      echo "Assuming: " & basePath / "output"
      config.setSectionKey("", "outputPath", basePath / "output")

  config.setSectionKey("", "templatePath", basePath / config.getSectionValue("", "templatePath"))

  var content: JsonNode = newJObject()
  let hg = newHtmlGenerator(config)
  let fg = newFeedGenerator(config)
  
  # Set overall blog metadata from the config file
  content["blog_title"] = %* config.getSectionValue("general", "blogName")
  content["blog_url"] = %* config.getSectionValue("general", "blogUrl")
  content["blog_author"] = %* config.getSectionValue("general", "author")
  content["blog_description"] = %* config.getSectionValue("general", "blogDescription")
  # Get current time of building for the blog
  content["last_published"] = %* timeStart.utc.format("ddd', 'd MMM yyyy HH:mm:ss 'GMT'")
  content["articles"] = hg.walkContent(basePath / config.getSectionValue("", "contentPath"))
  
  asyncCheck deleteUnused(config, content)

  fg.makeFeeds(content)
  hg.generateIndexHtml(content)
  
  let timeEnd = now()
  echo "Built " & $ len(content["articles"]) & " pages in: ", (timeEnd - timeStart).inMilliseconds, "ms"

proc `template`(configFile="config.ini", 
                title: string, 
                description="Default description", 
                author="", 
                slug="changemetosomethingunique", 
                published=now().format("yyyy-mm-dd"),
                outputPath=""
               ): void =
  ## Creates a template blog post for you, could be used for scripting etc.
  var config = loadConfig(configFile)
  var cauthor = author
  
  # use the author specified in config file
  if author == "":
    cauthor = config.getSectionValue("general", "author")

  let metadata = %* {"title":title, 
                     "description":description,
                     "author":author,
                     "slug":slug,
                     "published":published}
 
  let contentPath = config.getSectionValue("", "basePath") / config.getSectionValue("", "contentPath")
  writeFile(contentPath / title.addFileExt "md", pretty metadata)

when isMainModule:
  dispatchMulti([publish], [`template`]) 
  # perhaps set publish as automatic like this
  # https://github.com/c-blake/cligen/blob/master/test/SemiAutoMulti.nim
