CleanPlugin = require 'clean-webpack-plugin'
webpack = require 'webpack'
path = require 'path'
pathToUtils = '.' + path.sep + path.join('webpack-config-builder','utils-js') + path.sep
utils = require pathToUtils + 'webpack.utils'

buildPreferences = require(pathToUtils + 'build.preferences')(process.env.BUILD_TYPE)

metadataExtension = 'meta.js'
generatedModuleExtension = 'gen.js'

rootDirectory = 'one-button'
buildDirectory = path.join rootDirectory, 'src', 'common'

contentDirectory = 'content'
pageDirectory = 'page'
backgroundDirectory = 'background'
inputDirectories = [contentDirectory, pageDirectory, backgroundDirectory]

entryResolver = new utils.EntryResolver
  files:
    include: /\.(coffee|ts|js)$/
  directories:
    exclude: /html|libs|raw|res|css|strings|values/

extesionConfigPlugin = new utils.ExtesionConfigPlugin
  pathToConfig: path.join rootDirectory, 'config.json'
  outputPath: buildDirectory
  inputDirectories: inputDirectories
  configEncoding: 'utf8'

module.exports = for inputDirectory in inputDirectories
  outputPath = path.join buildDirectory, inputDirectory
  entries = entryResolver.getEntries path.join(rootDirectory, inputDirectory)
  isContentScript = inputDirectory isnt backgroundDirectory

  extesionConfigPlugin.setOptions
    entries: entries
    inputDirectory: inputDirectory
    fileExtension: if isContentScript then metadataExtension else generatedModuleExtension
    isContentScript: isContentScript

  plugins = [
    new webpack.NoErrorsPlugin
    new CleanPlugin outputPath,
      verbose: false
    extesionConfigPlugin
  ]

  if isContentScript
    plugins.push new utils.MetadataPlugin
        generatedModuleExtension: generatedModuleExtension
        metadataExtension: metadataExtension
        rootDirectory: rootDirectory
        entries: entries
        outputPath: outputPath
        inputDirectory: inputDirectory
        isInPageContext: inputDirectory is pageDirectory

  buildPreferences.addOptimizePlugins plugins

  config =
    entry: entries
    output:
      path: outputPath
      filename: '[name].' + generatedModuleExtension
    devtool: buildPreferences.getDevTool()
    plugins: plugins
    module:
      loaders: [
        { test: /\.css$/, loader: 'style!css' }
        { test: /\.less$/, loader: 'style!css!less' }
        { test: /\.tsx?$/, loader: 'ts-loader' }
        { test: /\.coffee$/, loader: 'coffee-loader' }
        { test: /\.handlebars$/, loader: 'handlebars-template-loader' }
        { test: /\.(png|jpg|svg|ttf|eot|woff|woff2)$/, loader: 'url' }
      ]
