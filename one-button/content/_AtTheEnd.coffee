# Script that will run at the end

OButtonCore = require '../core/_AtTheEnd.coffee'

class OButtonCoreInContentContext extends OButtonCore
  constructor: ->
    super 'content'

  initializeOnClickListener: (onClick) ->
    kango.addMessageListener 'click', (e) -> onClick e?.data

  onClick: (dataFromBackground) =>
    @triggerClickToPageContext dataFromBackground
    super dataFromBackground

  triggerClickToPageContext: (dataFromBackground = {}) =>
    try
      body = document.getElementsByTagName("body")[0]
      body.setAttribute('data-obutton-click', JSON.stringify(dataFromBackground))
    catch e
      console.log 'Impossible to set body attribute: ', e

new OButtonCoreInContentContext().run()
