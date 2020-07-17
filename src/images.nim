import parsecfg, json, os

proc copyImages*(config: Config): JsonNode =
  ## Procedure to copy images smart-ly
  ##
  ## Implementations in the config 'fast mode vs slow mode'
  ## fast checks filesize only, slow checks file hashes
  ##
  ## Returns a json node of all the relative urls of images
  
  # Images are in contentPath/images and output to outputPath/images
  # This allows relative linking from within the document
  let imagePath = config.getSectionValue("", "basePath") / config.getSectionValue("", "contentPath") / "images"
  let imageOutputPath = config.getSectionValue("", "outputPath") / "images"
  var images: seq[string]

  for kind, file in walkDir(imagePath):
    if kind == pcFile:
      let outputFile = imageOutputPath / file.extractFilename
      # compare to the other one somehow
      if not outputFile.fileExists:
        copyFile(file, outputFile)
      elif outputFile.fileExists and file.getFilesize != outputFile.getFilesize:
        copyFile(file, outputFile)
      images.add(outputFile)
  
  return %* images
