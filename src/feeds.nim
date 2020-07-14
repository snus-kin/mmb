import json, parsecfg, xmltree, strutils
## lets make xml feeds here from json objects
##
## TODO read the rss/atom spec
## TODO work out a nice way to make these
type feedGenerator* = ref object of RootObj
  rssEnabled: bool
  rssPath: string
  atomEnabled: bool
  atomPath: string
  jsonEnabled: bool
  jsonPath: string

proc newFeedGenerator*(config: Config): feedGenerator =
  let basePath = config.getSectionValue("", "basePath")
  let outputPath = basePath & '/' & config.getSectionValue("", "outputPath") & '/'
  result = feedGenerator(
    rssEnabled : config.getSectionValue("feeds", "rss").parseBool,
    rssPath: outputPath & config.getSectionValue("feeds", "rssFile"),
    atomEnabled : config.getSectionValue("feeds", "atom").parseBool,
    atomPath: outputPath & config.getSectionValue("feeds", "atomFile"),
    jsonEnabled : config.getSectionValue("feeds", "json").parseBool,
    jsonPath: outputPath & config.getSectionValue("feeds", "jsonFile")
  )

proc makeRSS(fg: feedGenerator, blog: JsonNode): void =
  ## https://validator.w3.org/feed/docs/rss2.html
  ## <channel>
  ##  title, link, description, pubDate, image?
  ## <item>
  ##  title, link, description, pubDate, author, source
  var tagList: array[5, XmlNode]
  taglist[0] = <>title(newText(blog["blog_title"].getStr))
  taglist[1] = <>link(newText(blog["blog_url"].getStr))
  taglist[2] = <>description(newText(blog["blog_description"].getStr))
  taglist[3] = <>pubDate(newText(blog["last_published"].getStr))

  if fg.atomEnabled:
    # sadly can't use the macro here cos namespace 
    taglist[4] = newElement("atom:link")
    taglist[4].attrs = {"href": blog["blog_url"].getStr & fg.atomPath,
                        "rel": "self", 
                        "type":"application/rss+xml"}.toXmlAttributes

  let channel = newXmlTree("channel", taglist)

  # loop over articles, each is a new item
  for item in blog["articles"]:
    let itemTag = newElement("item")

  let feedattr = {"version": "2.0", "xmlns:atom": "http://www.w3.org/2005/Atom"}.toXmlAttributes
  let feed = newXmlTree("rss", [channel], feedattr)
 
  # add the xml header before writing 
  var xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
  # there's no nice way of getting the raw XML w/ no indent 
  # '$' is pretty print, why?
  xmlString.add(feed, addNewLines=false, indWidth=0)
  writeFile(fg.rssPath, xmlString)

proc makeAtom(fg: feedGenerator, blog: JsonNode): void =
  ## https://validator.w3.org/feed/docs/atom.html
  ## more complex
  discard

proc makeJson(fg: feedGenerator, blog: JsonNode): void =
  ## Just write the json to the file, no need to process
  writeFile(fg.jsonPath, $ blog)
  discard

proc makeFeeds*(fg: feedGenerator, blog: JsonNode): void =
  ## Just bundle these nicely for public use
  if fg.rssEnabled:
    fg.makeRSS(blog)
  if fg.atomEnabled:
    fg.makeAtom(blog)
  if fg.jsonEnabled:
    fg.makeJson(blog)
