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
inputDirectories = [contentDirectory, 'background']

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

  extesionConfigPlugin.setOptions
    entries: entries
    inputDirectory: inputDirectory
    fileExtension: if inputDirectory is contentDirectory then metadataExtension else generatedModuleExtension

  plugins = [
    new webpack.NoErrorsPlugin
    new CleanPlugin outputPath,
      verbose: false
    extesionConfigPlugin
  ]

  if inputDirectory is contentDirectory
    plugins.push new utils.MetadataPlugin
        generatedModuleExtension: generatedModuleExtension
        metadataExtension: metadataExtension
        rootDirectory: rootDirectory
        entries: entries
        outputPath: outputPath
        inputDirectory: inputDirectory

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
        { test: /\.(handlebars|html)$/, loader: 'handlebars-template-loader' }
        { test: /\.(png|jpg|svg|ttf|eot|woff|woff2)$/, loader: 'url' }
      ]
