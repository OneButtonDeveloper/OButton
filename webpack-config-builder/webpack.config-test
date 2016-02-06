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

module.exports =
  # path to entry points
  context: __dirname + "/test"
  entry:
    test: ["./test00", "./test"]
  output:
    path: __dirname + "/test/build"
    filename: "[name].js"
    library: "[name]"
  devtool: buildTypeResolver.getDevTool()
  plugins: [
    new webpack.NoErrorsPlugin() # don't create files if build has errors
  ]
  # require('<lib>') ≈ var externals[<lib>];
  externals: {
    "jQuery": "$"
    "OButton": "OButton"
    "kango": "kango"
  }
  module: {
    loaders: []
    #noParse: /regExp/ - modules that will be ignored of webpack-compiler (not looking for "require" in files)
  }

buildTypeResolver.compressPlugin(module.exports)
