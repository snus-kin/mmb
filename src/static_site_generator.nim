import times
import html_generation

when isMainModule:
  let timeStart = now()
  generateHtmlFiles()
  let timeEnd = now()
  echo "Built site in: ", (timeEnd - timeStart).inMilliseconds, "ms"
