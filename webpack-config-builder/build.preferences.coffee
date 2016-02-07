class BuildTypePreferences
  @create: (buildType = 'development') ->
    switch buildType
      when 'development' then new DevelopmentBuildTypePreferences()
      when 'production' then new ProductionBuildTypePreferences()
  getDevTool: ->
  addOptimizePlugins: (plugins) ->

class DevelopmentBuildTypePreferences extends BuildTypePreferences
# TODO:  getDevTool: -> 'eval'

class ProductionBuildTypePreferences extends BuildTypePreferences
  addOptimizePlugins: (plugins) ->
    plugins.push new webpack.optimize.UglifyJsPlugin
      compress:
        warnings: false
        drop_console: true
        unsafe: true

module.exports = BuildTypePreferences.create
