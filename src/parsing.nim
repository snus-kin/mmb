import json
import markdown

proc parseArticle*(file: string): JsonNode =
  ## Procedure to parse markdown from a single file
  ##
  ## Markdown files are prefaced with a json object that
  ## embeds metadata such as title, date etc.
  ##
  ## This returns a json node that contains the metadata of an article
  ## and the content itself, this can then be used to create a context 
  ## for Moustache
  let articleFile = readFile(file)

  # The header metadata of this file is wrapped in '{' and '}' so we find the index
  # of the first '{' and the first '}' and assume that to be the header,
  # creating a new substring
  let headerStart = articleFile.find('{')
  let headerEnd = articleFile.find('}')
  let header = articleFile[headerStart .. headerEnd]

  let article = newJObject()

  # now parse the file itself
  try:
    article["metadata"] = parseJson(header)
    # add .html to the end of the slug so things work later, perhaps there's a nicer way of doing this
    article["metadata"]["slug"] = %* (article["metadata"]["slug"].getStr & ".html")
    article["content"] = %* markdown(articleFile[headerEnd+1 ..< len(articleFile)])
    return article
  except JsonParsingError:
    stderr.writeLine("ERROR File: " & file & " has a malformed header")
    quit(1)
  except MarkdownError:
    stderr.writeLine("ERROR File: " & file & " markdown parsing error")
    quit(1)
  raise newException(ValueError, "Some unspecified parsing error occured")
