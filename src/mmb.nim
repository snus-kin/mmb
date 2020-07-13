import times, os
import html_generation, parsing

let basePath = getCurrentDir() & "/env"

proc walkContent(directory: string): void =
  let contentPath = basePath & "/content"
  # now we do the walking
  for kind, file in walkDir(contentPath):
    if kind == pcFile:
      echo file
      let article = parseArticle(file)
      generateArticleHtml(article)

when isMainModule:
  let timeStart = now()
  walkContent("content")
  let timeEnd = now()
  echo "Built site in: ", (timeEnd - timeStart).inMilliseconds, "ms"
