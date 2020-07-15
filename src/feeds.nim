import json, parsecfg, xmltree, strutils, asyncdispatch, os
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
  let outputPath = config.getSectionValue("", "outputPath")
  result = feedGenerator(
    rssEnabled : config.getSectionValue("feeds", "rss").parseBool,
    rssPath: outputPath / config.getSectionValue("feeds", "rssFile"),
    atomEnabled : config.getSectionValue("feeds", "atom").parseBool,
    atomPath: outputPath / config.getSectionValue("feeds", "atomFile"),
    jsonEnabled : config.getSectionValue("feeds", "json").parseBool,
    jsonPath: outputPath / config.getSectionValue("feeds", "jsonFile")
  )

proc makeRSS(fg: feedGenerator, blog: JsonNode) {.async.} =
  ## https://validator.w3.org/feed/docs/rss2.html
  ## <channel>
  ##  title, link, description, pubDate, atom:link
  ## <item>
  ##  title, link, description, pubDate, author, source
  var channel: seq[XmlNode]
  channel.add <>title(newText(blog["blog_title"].getStr))
  channel.add <>link(newText(blog["blog_url"].getStr))
  channel.add <>description(newText(blog["blog_description"].getStr))
  channel.add <>pubDate(newText(blog["last_published"].getStr))

  if fg.atomEnabled:
    # sadly can't use the macro here because the : in the xml
    let atomLink = newElement("atom:link")
    atomLink.attrs = {"href": blog["blog_url"].getStr & fg.atomPath,
                      "rel": "self", 
                      "type":"application/rss+xml"}.toXmlAttributes
    channel.add atomLink

  # loop over articles, each is a new item
  for item in blog["articles"]:
    var itemNodes: seq[XmlNode]
    itemNodes.add <>title(newText(item["metadata"]["title"].getStr))
    itemNodes.add <>link(newText(blog["blog_url"].getStr & item["metadata"]["slug"].getStr))
    itemNodes.add <>description(newText(item["metadata"]["description"].getStr))
    itemNodes.add <>pubDate(newText(item["metadata"]["published"].getStr))
    itemNodes.add <>author(newText(item["metadata"]["author"].getStr))
    channel.add newXmlTree("item", itemNodes) 

  let channelTree = newXmlTree("channel", channel)
  let feed = <>rss(channelTree)
  feed.attrs = {"version":"2.0", "xmlns:atom":"http://www.w3.org/2005/Atom"}.toXmlAttributes
 
  # add the xml header before writing 
  var xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
  # there's no nice way of getting the raw XML w/ no indent 
  # '$' is pretty print, why?
  xmlString.add(feed, addNewLines=false, indWidth=0)
  writeFile(fg.rssPath, xmlString)

proc makeAtom(fg: feedGenerator, blog: JsonNode) {.async.} =
  ## https://validator.w3.org/feed/docs/atom.html
  ## more complex
  discard

proc makeJson(fg: feedGenerator, blog: JsonNode) {.async.} =
  ## Just write the json to the file, no need to process
  writeFile(fg.jsonPath, $ blog)
  discard

proc makeFeeds*(fg: feedGenerator, blog: JsonNode): void =
  ## Just bundle these nicely for public use
  if fg.rssEnabled:
    asyncCheck fg.makeRSS(blog)
  if fg.atomEnabled:
    asyncCheck fg.makeAtom(blog)
  if fg.jsonEnabled:
    asyncCheck fg.makeJson(blog)
