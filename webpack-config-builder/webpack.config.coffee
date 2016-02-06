utils = require './webpack-config-builder/utils-js/webpack.utils'
CleanPlugin = require 'clean-webpack-plugin'
webpack = require 'webpack'
path = require 'path'

{ BUILD_TYPE, MODULE_NAME } = process.env

class BuildTypeResolver
  @create: (buildType = 'development') ->
    switch buildType
      when 'development' then new DevelopmentBuildTypeResolver()
      when 'production' then new ProductionBuildTypeResolver()
  getDevTool: ->
  compressPlugin: (plugins) ->

class DevelopmentBuildTypeResolver extends BuildTypeResolver
# TODO:  getDevTool: -> 'eval'

class ProductionBuildTypeResolver extends BuildTypeResolver
  compressPlugin: (plugins) ->
    plugins.push new webpack.optimize.UglifyJsPlugin
      compress:
        warnings: false
        drop_console: true
        unsafe: true

buildTypeResolver = BuildTypeResolver.create(BUILD_TYPE)

generatedModuleExtension = 'gen.js'
commonJsFileName = '_Common'

entryResolver = new utils.EntryResolver()

root_dir = 'one-button'
build_dir = path.join root_dir, 'build-wp'

content_dir = 'content'
input_directoties = [content_dir, 'background'] # WARN! content_dir must be first

outputConfigPath = path.join __dirname, build_dir
inputConfigPath = path.join __dirname, root_dir, content_dir, 'config.json'

#extesionConfigPlugin = new utils.ExtesionConfigPlugin
#  generatedModuleExtension: generatedModuleExtension
#  commonJsFileName: commonJsFileName
#  extensionConfig: inputConfigPath
#  outputPath: outputConfigPath

configs = for input_dir in input_directoties
  outputPath = path.join outputConfigPath, input_dir

  entries = entryResolver.getEntries
    directory: path.join root_dir, input_dir
    files:
      include: /\.(coffee|ts|js)$/
    folders:
      exclude: /html|libs|raw|res|css|strings|values/

  plugins = [ new webpack.NoErrorsPlugin() ]
  if input_dir is content_dir
    plugins = plugins.concat [
      new CleanPlugin path.join __dirname, build_dir
      new webpack.optimize.CommonsChunkPlugin
        name: commonJsFileName
        minChunks: 2
      new utils.MetadataPlugin
        entries: entries
        inputDirectory: input_dir
        outputPath: outputPath
        commonJsFileName: commonJsFileName
        generatedModuleExtension: generatedModuleExtension
      ]
#  extesionConfigPlugin.setOptions
#    inputDirectory: input_dir
#    entries: entries
#  plugins.push extesionConfigPlugin
  buildTypeResolver.compressPlugin plugins

  config =
    context: __dirname
    entry: entries
    output:
      path: outputPath
      filename: '[name].' + generatedModuleExtension
    devtool: buildTypeResolver.getDevTool()
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

module.exports = configs
