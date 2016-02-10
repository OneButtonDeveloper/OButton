# Script that will run at the end

class OButtonCore
  constructor: (contextName) ->
    @container = OButton
    @inContext = "in the #{contextName} context"

  run: =>
    if @canInitialize()
      @initializeModules()
      @initializeOnClickListener @onClick

  canInitialize: =>
    unless @container?
      console.log "!!! Impossible to initialize OButtonCore. OButton not defined #{@inContext}"
    @container?

  firstTimeClick: {}
  initializeModules: =>
    console.log "Initialization of modules #{@inContext}"
    for name, module of @container
      @firstTimeClick[name] = yes
      if module.initialize?
        try
          module.initialize()
          console.log "Module #{ name } initialized #{@inContext}"
        catch e
          console.log "Module #{ name } not initialized #{@inContext}. See error: ", e

  initializeOnClickListener: (onClick) ->
    throw 'onClickListener must be implemented in a child class'

  onClick: (dataFromBackground) =>
    # TODO: made router nicer
    # TODO: regex: //, onEnter, onLeave, onClick (isFirstTime, dataFromBackground)
    # TODO: use getInstance() instead of global functions
    console.log "onClick #{@inContext} with data: ", dataFromBackground
    for name, module of @container
      if module.onceOnClick? and firstTimeClick[name]
        if not module.urlRegEx? or module.urlRegEx.test window.location.href
          console.log name + '.onceOnClick()'
          module.onceOnClick()
          firstTimeClick[name] = no
      if module.onClick?
        console.log name + '.onClick()'
        module.onClick()

module.exports = OButtonCore
