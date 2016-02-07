path = require 'path'
os = require 'os'
fs = require 'fs'
mkdirp = require 'mkdirp'
readline = require 'readline'

class FileUtils
  walk: (context, dir, callback) ->
    currentContext = path.join context, dir
    results = fs.readdirSync currentContext
    files = []
    dirs = []
    for f in results
      fullPath = path.join currentContext, f
      stat = fs.statSync fullPath
      files.push f if stat.isFile()
      dirs.push f if stat.isDirectory()
    if callback context, dir, dirs, files
      for dir in dirs
        @walk currentContext, dir, callback

  zIgroring: /^z.+/
  isInclude: (title, options) ->
    if (options.zIgroring ? true) and @zIgroring.test title then return false
    if options.exclude?.test title then return false
    return not options.include? or options.include.test title

  getFiles: (context, dir, options = {}) ->
    result = []
    @walk context, dir, (context, dir, dirs, files) =>
      for file in files
        if @isInclude file, options
          result.push path.join dir, file
      options.isRecursive
    result

  getDirectories: (context, dir, options = {}) ->
    result = []
    @walk context, dir, (context, dir, dirs, files) =>
      for directory in dirs
        if @isInclude directory, options
          result.push directory
      options.isRecursive
    result

  getLines: (pathToFile, pattern, include, options, callback) ->
    lines = []
    lineReader = readline.createInterface
      input: fs.createReadStream pathToFile
    lineReader.on 'line', (line = "") ->
      if pattern.test line
        if include.test line
          lines.push line
      else
        lineReader.close()
    lineReader.on 'close', ->
      callback options, lines

  createFile: (pathToFile, fileContent) ->
    fs.writeFileSync(pathToFile, fileContent)

  readFile: (pathToFile, encoding) ->
    fs.readFileSync pathToFile, encoding

  fileExists: (filePath) ->
    try
      return fs.statSync(filePath).isFile()
    catch err
      return false

  copyFileTo: (pathToFile, newPathToFile) ->
    mkdirp.sync path.dirname newPathToFile
    fs.createReadStream(pathToFile).pipe(fs.createWriteStream newPathToFile)

  buildFile: (pathToFile, options, builder) ->
    lines = []
    builder options, lines
    fs.writeFileSync pathToFile, lines.join os.EOL

module.exports = FileUtils
