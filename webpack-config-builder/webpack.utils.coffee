path = require 'path'
chalk = require 'chalk'

FileUtils = require './file.utils'
fileUtils = new FileUtils()

WebPackUtils = {}


class WebPackUtils.EntryResolver
  constructor: (options = {}) ->
    { @files, @directories, @context } = options
    if not @files? or not @files.include? then throw chalk.red 'Set files.include param of getEntities() Ex. /\.(coffee|ts|js)$/'
    @context ?= ""

  getEntries: (directory) ->
    unless directory? then throw chalk.red 'Set a directory param of getEntities() - directory with modules (Ex. "content")'

    entries = {}
    for file in fileUtils.getFiles @context, directory, @files
      @setEntryTo entries, file

    topDirectories = fileUtils.getDirectories @context, directory, @directories
    newContext = path.join @context, directory
    for topDirectory in topDirectories
      modules = fileUtils.getFiles newContext, topDirectory, @files
      index = @getIndexJs modules, topDirectory
      if index
        @setEntryTo entries, path.join(directory, index), topDirectory
    entries

  setEntryTo: (entries, file, directory) ->
    name = if directory then directory else @withoutExtension path.basename file
    entries[name] = '.' + path.sep + file

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
    { @outputPath, @inputDirectory, @rootDirectory, metadataExtension, entries, generatedModuleExtension } = options
    @entries = []
    for moduleName, sourcePath of entries
      @entries.push
        moduleName: moduleName
        fileName: moduleName + '.' + generatedModuleExtension
        metadataFileName: moduleName + '.' + metadataExtension
        sourcePath: sourcePath
        includes: []
        requires: []

  clearSetting: (setting) ->
    setting.replace(@SETTING_PREFIX, "").trim()

  apply: (compiler) ->
    compiler.plugin "done", =>
      for options in @entries
        fileUtils.getLines options.sourcePath, @COMMENT_OR_EMPTY_LINE, @SETTING, options, @onReadSettingsComplete

  onReadSettingsComplete: (options, settings) =>
    for setting in settings
      if @SETTING_ERROR.test setting
        throw chalk.red "ERROR! The setting for metadata in file #{options.sourcePath} is invalid. Check syntax of 'include' or 'require' comment"
      (options.includes.push @clearSetting setting) if @INCLUDE_SETTING.test setting
      (options.requires.push @clearSetting setting) if @REQUIRE_SETTING.test setting
    @runContentScriptInPageContext path.join(@outputPath, options.fileName)
    @buildFileFromOptions path.join(@outputPath, options.metadataFileName), options

  runContentScriptInPageContext: (pathToOutputJs) ->
    if fileUtils.fileExists pathToOutputJs
      content = fileUtils.readFile pathToOutputJs, 'utf8'
      content = content.replace(/\\/g, "\\\\").replace(/"/g, "\\\"")
      content = 'var s = document.createElement("script");s.type="text/javascript";s.innerText="' + content + '";document.getElementsByTagName("head")[0].appendChild(s);'
      fileUtils.createFile pathToOutputJs, content

  buildFileFromOptions: (pathToFile, options) =>
    fileUtils.buildFile pathToFile, options, (metadata, lines) =>
      { includes, requires, fileName, sourcePath } = metadata
      lines.push '// ==UserScript=='
      for include in @resolveIncludes includes
        lines.push '// @include ' + include
      for lib in @resolveRequires requires, sourcePath, fileName
        lines.push '// @require ' + lib
      lines.push '// ==/UserScript=='
    @log '[MetadataPlugin] files created:', pathToFile

  log: (title, pathToFile) =>
    unless @title?
      console.log chalk.bold title
      @title = title
    console.log '\t' + chalk.green.bold path.basename(pathToFile)

  resolveIncludes: (includes) ->
    if includes.length <= 0 then DEFAULT_INCLUDES else includes

  resolveRequires: (requires = [], sourcePath, moduleFileName) ->
    result = []
    for lib in requires
      pathToLib = @resolvePathToLib sourcePath, lib
      shortPath = pathToLib.replace @rootDirectory + path.sep, ''
      fileUtils.copyFileTo pathToLib, path.join @outputPath, shortPath.replace @inputDirectory + path.sep, ''
      result.push shortPath
    result.push path.join @inputDirectory, moduleFileName
    result

  resolvePathToLib: (sourcePath, lib) ->
    lib = if lib.indexOf('.js') <= 0 then lib + '.js' else lib
    level = 2
    root = sourcePath
    while level > 0
      root = path.dirname root
      currentPath = path.join root, 'libs', lib
      if fileUtils.fileExists currentPath
        return currentPath
      currentPath = path.join root, lib
      if fileUtils.fileExists currentPath
        return currentPath
      level--
    throw chalk.red "ERROR! Impossible to find library #{lib} for #{sourcePath}"


class WebPackUtils.ExtesionConfigPlugin
  priority:
    _AtTheBeginning: 0
#   otherJsFileNames: 1
    _AtTheEnd: 2

  scripts: {}
  countDirectoriesCompiled: 0

  sortValue: (value) -> (@priority[value] ? 1) + value

  constructor: (options = {}) ->
    { @outputPath, @pathToConfig, @inputDirectories, @configEncoding } = options

  setOptions: (options) ->
    { entries, inputDirectory, fileExtension } = options
    fileNames = (key for key, value of entries)
    fileNames.sort (value1, value2) => @sortValue(value1).localeCompare @sortValue(value2)
    fileNames = for fileName in fileNames
      path.join(inputDirectory, fileName + '.' + fileExtension)
    @scripts[inputDirectory] = fileNames.join '", "'

  apply: (compiler) ->
    compiler.plugin "done", =>
      unless ++@countDirectoriesCompiled is @inputDirectories.length then return
      configFileContent = fileUtils.readFile @pathToConfig, @configEncoding
      for key, value of @scripts
        configFileContent = configFileContent.replace "%#{key}_scripts%", value
      fileUtils.createFile path.join(@outputPath, 'extension_info.json'), configFileContent
      console.log chalk.bold "[ExtesionConfigPlugin] #{chalk.green 'extension_info.json created'}"


module.exports = WebPackUtils
