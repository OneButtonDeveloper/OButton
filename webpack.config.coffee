{ BUILD_TYPE, MODULE_NAME } = process.env

webpack = require "webpack"

class BuildTypeResolver
  @create: (buildType = 'development') ->
    switch buildType
      when 'development' then new DevelopmentBuildTypeResolver()
      when 'production' then new ProductionBuildTypeResolver()
  getDevTool: ->
  compressPlugin: (exports) ->

class DevelopmentBuildTypeResolver extends BuildTypeResolver
# TODO:  getDevTool: -> 'eval'

class ProductionBuildTypeResolver extends BuildTypeResolver
  compressPlugin: (exports) ->
    (exports.plugins ?= []).push new webpack.optimize.UglifyJsPlugin
        compress:
          warnings: false
          drop_console: true
          unsafe: true

buildTypeResolver = BuildTypeResolver.create(BUILD_TYPE)

input_dir = '/one-button/content'
build_dir = '/one-button/build-wp'
output_dir = build_dir + '/content'

#plugin will allow use watch: true and hot-reloading for debugging separate modules
class TestPlugin
  apply: (compiler) ->
    compiler.plugin "compile", (params) ->
      console.log "The compiler is starting to compile..."

    compiler.plugin "emit", (compilation, callback) ->
      console.log "The compilation is going to emit files..."
      callback();

    compiler.plugin "done",  ->
      console.log "Done"

CleanWebpackPlugin = require 'clean-webpack-plugin'

module.exports =
  # path to entry points
  context: __dirname + input_dir
  entry:
    GithubExtension: "./GithubExtension/GithubExtension.coffee"
    LorenIpsum: "./LorenIpsum/Randomizer.coffee"
  output:
    path: __dirname + output_dir
    filename: "[name].gen.js"
  devtool: buildTypeResolver.getDevTool()
  plugins: [
    new CleanWebpackPlugin __dirname + build_dir
    new webpack.NoErrorsPlugin()
    new webpack.optimize.CommonsChunkPlugin
      name: "Common"
      minChunks: 2
    new TestPlugin()
  ]
  module:
    loaders: [
      { test: /\.coffee$/, loader: "coffee-loader" }
      { test: /\.(coffee\.md|litcoffee)$/, loader: "coffee-loader?literate" }
      { test: /\.css$/, loader: "style!css" }
      { test: /\.less$/, loader: "style!css!less" }
      { test: /\.(handlebars|html)$/, loader: "handlebars-template-loader" }
      { test: /\.tsx?$/, loader: 'ts-loader' }
      { test: /\.(png|jpg|svg|ttf|eot|woff|woff2)$/, loader: 'url?name=[name].[ext]' }
    ]

buildTypeResolver.compressPlugin(module.exports)
