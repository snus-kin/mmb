import times, os, json
import html_generation, parsing

let basePath = getCurrentDir() & "/env"

proc walkContent(directory: string): JsonNode =
  let contentPath = basePath & "/content"
  let articles = newJArray()
  # now we do the walking
  for kind, file in walkDir(contentPath):
    if kind == pcFile:
      let article = parseArticle(file)
      articles.add article
      # generate a html file at each node
      generateArticleHtml(article)

  return articles

when isMainModule:
  let timeStart = now()
  var content: JsonNode = newJObject()
  content["blog_title"] = %* "BLOG TITLE!"
  content["articles"] = walkContent("content")
  generateIndexHtml(content)
  echo pretty(content)
  let timeEnd = now()
  echo "Built site in: ", (timeEnd - timeStart).inMilliseconds, "ms"
