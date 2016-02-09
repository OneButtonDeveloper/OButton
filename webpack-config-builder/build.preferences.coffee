webpack = require 'webpack'

class BuildTypePreferences
  @create: (buildType = 'development') ->
    switch buildType
      when 'development' then new DevelopmentBuildTypePreferences()
      when 'production' then new ProductionBuildTypePreferences()
  getDevTool: ->
  addOptimizePlugins: (plugins) ->

class DevelopmentBuildTypePreferences extends BuildTypePreferences
  addOptimizePlugins: (plugins) ->
    plugins.push new webpack.optimize.UglifyJsPlugin
      compress:
        warnings: false
        drop_console: false
        unsafe: false
        keep_fnames: true
# TODO:  getDevTool: -> 'eval'

class ProductionBuildTypePreferences extends BuildTypePreferences
  addOptimizePlugins: (plugins) ->
    plugins.push new webpack.optimize.UglifyJsPlugin
      compress:
        warnings: false
        drop_console: true
        unsafe: true
        keep_fnames: false

module.exports = BuildTypePreferences.create
