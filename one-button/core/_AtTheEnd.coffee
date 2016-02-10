# Script that will run at the end

isFunction = (f) ->
  return f? and {}.toString.call(f) is '[object Function]'

isArray = (f) ->
  return f? and {}.toString.call(f) is '[object Array]'

class OButtonCore
  constructor: (contextName) ->
    @container = OButton
    @inContext = "in the #{contextName} context"
    @routers = []

  run: =>
    if @canInitialize()
      @initializeModules()
      @intializeLocationListener()
      @initializeOnClickListener @onClick

  canInitialize: =>
    unless @container?
      console.log "!!! Impossible to initialize OButtonCore. OButton not defined #{@inContext}"
    @container?

  initializeModules: =>
    console.log "Initialization of modules #{@inContext}"
    for name, module of @container
      try
        module.initialize?()
        @intializeRouter module
        console.log "Module #{ name } initialized #{@inContext}"
      catch e
        console.log "Module #{ name } not initialized #{@inContext}. See error: ", e

  initializeOnClickListener: (onClick) ->
    throw 'onClickListener must be implemented in a child class'

  onClick: (dataFromBackground) =>
    console.log "onClick #{@inContext} with data: ", dataFromBackground
    for name, module of @container
      module.onClick?(dataFromBackground) # very simple onClick
    @routersUpdate true, dataFromBackground

  intializeRouter: (module) ->
    if router = module.router
      router = if isFunction router then router() else router
      if isArray router
        @routers.push.apply @routers, router
      else
        @routers.push router

  routersUpdate: (isOnClick, dataFromBackground) =>
    @routerWalk null, @routers, isOnClick, dataFromBackground

  routerWalk: (parentRouter, routers, isOnClick, dataFromBackground) =>
    unless routers? then return
    for router in routers
      @runRouter parentRouter, router, isOnClick, dataFromBackground
      @routerWalk router, router.routers, isOnClick, dataFromBackground

  runRouter: (parentRouter, router, isOnClick, dataFromBackground) ->
    isActive = if parentRouter then parentRouter.isActive else true
    isActive = isActive and router.url.test window.location.href
    if not router.isActive and isActive
      router.isActive = isActive
      router.isFirstTimeClick = null
      router.onEnter?()
    if router.isActive and not isActive
      router.isActive = isActive
      router.onLeave?()
    if router.isActive and isOnClick
      router.onClick?(router.isFirstTimeClick ? true, dataFromBackground)
      router.isFirstTimeClick = false

  intializeLocationListener: =>
    @previousHrefValue = window.location.href.slice(0)
    @routersUpdate()
    onTimeout = =>
      if @previousHrefValue isnt window.location.href
        @previousHrefValue = window.location.href.slice(0)
        @routersUpdate()
    ticker = ->
      onTimeout()
      setTimeout ticker, 100
    ticker()

module.exports = OButtonCore
