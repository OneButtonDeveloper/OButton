os = require 'os'
fs = require 'fs'
path = require 'path'
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

  fileExists: (filePath) ->
    try
      return fs.statSync(filePath).isFile()
    catch err
      return false

  copyFileTo: (pathToFile, newPathToFile) ->
    mkdirp.sync path.dirname newPathToFile
    fs.createReadStream(pathToFile).pipe(fs.createWriteStream newPathToFile);

fileUtils = new FileUtils()

WebPackUtils = {}

class WebPackUtils.EntryResolver
  getEntries: (options = {}) ->
    { files, folders, context, directory } = options
    if not files? or not files.include? then throw 'Set an files.include param of getEntities() Ex. /\.(coffee|ts|js)$/'
    unless directory? then throw 'Set a directory param of getEntities() - folder with modules ("content")'
    context ?= ""

    entries = {}
    for file in fileUtils.getFiles context, directory, files
      @setEntryTo entries, file

    topDirectories = fileUtils.getDirectories context, directory, folders
    newContext = path.join context, directory
    for topDirectory in topDirectories
      modules = fileUtils.getFiles newContext, topDirectory, files
      index = @getIndexJs modules, topDirectory
      if index
        @setEntryTo entries, path.join(directory, index), topDirectory
    entries

  setEntryTo: (entries, file, directory) ->
    name = if directory
      directory
    else
      @withoutExtension path.basename file
    entries[name] =  '.' + path.sep + file

  withoutExtension: (fileName) ->
    fileName.replace /\.[^\.]+$/, ''

  getIndexJs: (modules = [], topDirectory) ->
    hashMap = @convertModules modules
    if module = hashMap['index'] then return module
    if module = hashMap[topDirectory.toLowerCase()] then return module
    return modules[0]

  convertModules: (modules) ->
    result = {}
    for module in modules
      moduleName = path.basename module.toLowerCase()
      result[@withoutExtension moduleName] = module
    result

class WebPackUtils.MetadataPlugin
  COMMENT_OR_EMPTY_LINE: /^(((\/+|#+).*)|(\s*))$/
  SETTING: /^(\/+|#+)\s?(include|require)\s.+$/
  SETTING_PREFIX: /^(\/+|#+)\s?(include|require)\s/

  SETTING_ERROR: /^(\/+|#+)\s?(includes|requires)\s.+$/
  INCLUDE_SETTING: /^(\/+|#+)\s?include\s.+$/
  REQUIRE_SETTING: /^(\/+|#+)\s?require\s.+$/

  DEFAULT_INCLUDES = [ "http://*", "https://*", "about:blank" ]

  constructor: (options = {}) ->
    { @outputPath, @inputDirectory, entries, commonJsFileName, @generatedModuleExtension } = options
    @entries = {}
    for moduleName, sourcePath of entries
      @entries[moduleName] =
        fileName: moduleName + '.' + @generatedModuleExtension
        sourcePath: sourcePath
    @commonJsFileName = commonJsFileName + '.' + @generatedModuleExtension

  clearSetting: (setting) ->
    setting.replace(@SETTING_PREFIX, "").trim()

  apply: (compiler) ->
    compiler.plugin "done",  =>
      for moduleName, options of @entries
        fileUtils.getLines options.sourcePath, @COMMENT_OR_EMPTY_LINE, @SETTING, options, (options, settings) =>
          { sourcePath } = options
          includes = []
          requires = []
          for setting in settings
            if @SETTING_ERROR.test setting
              throw "ERROR! The setting for metadata in file #{sourcePath} contains error. Check syntax of 'include' or 'require' comments"
            (includes.push @clearSetting setting) if @INCLUDE_SETTING.test setting
            (requires.push @clearSetting setting) if @REQUIRE_SETTING.test setting
          @createFileFromMetadata
            includes: if includes.length <= 0 then DEFAULT_INCLUDES else includes
            sourcePath: sourcePath
            fileName: options.fileName
            requires: requires
      @createFileFromMetadata
        fileName: @commonJsFileName
        includes: DEFAULT_INCLUDES
        sourcePath: path.join @outputPath, @commonJsFileName

  createFileFromMetadata: (metadata) =>
    { fileName, includes, requires, sourcePath } = metadata
    requires = @resolvePathToLibs sourcePath, requires
    metadata = '// ==UserScript==' + os.EOL
    for include in includes
      metadata += '// @include ' + include + os.EOL
    for lib in requires
      metadata += '// @require ' + lib + os.EOL
    metadata += '// @require ' + fileName + os.EOL
    metadata += '// ==/UserScript==' + os.EOL
    fileUtils.createFile path.join(@outputPath, path.basename(fileName, @generatedModuleExtension) + 'meta.js'), metadata

  resolvePathToLibs: (sourcePath, requires = []) ->
    libs = []
    for lib in requires
      pathToLib = @resolvePathToLib sourcePath, lib
      shortPath = pathToLib.substr(pathToLib.indexOf(@inputDirectory)).replace @inputDirectory + path.sep, ''
      fileUtils.copyFileTo pathToLib, path.join @outputPath, shortPath
      libs.push shortPath
    libs

  resolvePathToLib: (sourcePath, lib) ->
    lib = if lib.indexOf('.js') <= 0 then lib + '.js' else lib
    level = 2
    root = sourcePath
    #@inputDirectory
    while level > 0
      root = path.dirname root
      currentPath = path.join root, 'libs', lib
      if currentPath.indexOf(@inputDirectory) > 0
        if fileUtils.fileExists currentPath
          return currentPath
      currentPath = path.join root, lib
      if currentPath.indexOf(@inputDirectory) > 0
        if fileUtils.fileExists currentPath
          return currentPath
      level--
    throw "ERROR! Impossible to find library #{lib} for #{sourcePath}"

# TODO: use the same Plugin to store all variables inside
class WebPackUtils.ExtesionConfigPlugin
  priority:
    _AtTheBeginning: 0
#   commonJsFileName: 1
#   otherJsFileNames: 2
    _AtTheEnd: 3

  sortValue: (value) -> (@priority[value] ? 2) + value

  constructor: (options = {}) ->
    # @outputPath where new config must be
    # @inputDirectory for replace according row in the config file
    # @extensionConfig for duplicate the config file if not exists
    { @outputPath, @inputDirectory, @extensionConfig, entries, generatedModuleExtension, commonJsFileName } = options
    @priority[commonJsFileName] = 1
    @fileNames = (key for key, value of entries)
    @fileNames.push commonJsFileName
    @fileNames.sort (value1, value2) => @sortValue(value1).localeCompare @sortValue(value2)
    @entries = {}
    for fileName in @fileNames
      @entries[fileName] =
        fileName: fileName + generatedModuleExtension
        filePath: entries[fileName]
  apply: (compiler) ->
    compiler.plugin "compile", (params) ->
      console.log "ExtesionConfigPlugin:The compiler is starting to compile..."
    compiler.plugin "done",  =>
      console.log "ExtesionConfigPlugin:Done", @fileNames, @entries

module.exports = WebPackUtils
