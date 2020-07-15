import json, parsecfg, xmltree, strutils, asyncdispatch, os, times
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
  ## Creates a new feedGenerator object from the config loaded in the main module
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
  ## Write an rss feed given a JsonNode of blog info and articles
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
    itemNodes.add <>link(newText(blog["blog_url"].getStr / item["metadata"]["slug"].getStr))
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
  ## Write an atom feed given JsonNode of blog info and articles
  var feed: seq[XmlNode]
  let rfc822format = initTimeFormat("ddd', 'd MMM yyyy HH:mm:ss 'GMT'")
  let rfc3339format = initTimeFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
  feed.add <>title(newText(blog["blog_title"].getStr))
  feed.add <>link(href=blog["blog_url"].getStr)
  feed.add <>id(newText(blog["blog_url"].getStr)) # id is just blog url
  feed.add <>author(<>name(newText(blog["blog_author"].getStr)))
  # time must be RFC3339 compliant
  feed.add <>updated(newText(blog["last_published"].getStr.parse(rfc822format).format(rfc3339format)))

  for item in blog["articles"]:
    var entryNodes: seq[XmlNode]
    entryNodes.add <>title(newText(item["metadata"]["title"].getStr))
    entryNodes.add <>link(href=blog["blog_url"].getStr / item["metadata"]["slug"].getStr)
    entryNodes.add <>id(newText(blog["blog_url"].getStr / item["metadata"]["slug"].getStr))
    entryNodes.add <>author(<>name(newText(item["metadata"]["author"].getStr)))
    entryNodes.add <>summary(newText(item["metadata"]["description"].getStr))
    entryNodes.add <>updated(newText(item["metadata"]["published"].getStr.parse(rfc822format).format(rfc3339format)))
    entryNodes.add <>content(newText(item["content"].getStr))

    feed.add newXmlTree("entry", entryNodes)
  
  let feedTree = newXmlTree("feed", feed, {"xmlns": "http://www.w3.org/2005/Atom"}.toXmlAttributes)
  var xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
  writeFile(fg.atomPath, xmlString & $ feedTree)

proc makeJson(fg: feedGenerator, blog: JsonNode) {.async.} =
  ## Just writes the json object to a file, no processing
  writeFile(fg.jsonPath, $ blog)

proc makeFeeds*(fg: feedGenerator, blog: JsonNode): void =
  ## Just bundle these nicely for public use
  ## When implementing categories it should be possible to just pass the category to this
  if fg.rssEnabled:
    asyncCheck fg.makeRSS(blog)
  if fg.atomEnabled:
    asyncCheck fg.makeAtom(blog)
  if fg.jsonEnabled:
    asyncCheck fg.makeJson(blog)
