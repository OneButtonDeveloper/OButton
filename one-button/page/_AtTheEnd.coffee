# Script that will run at the end

OButtonCore = require '../core/_AtTheEnd.coffee'

class OButtonCoreInPageContext extends OButtonCore
  constructor: ->
    super 'page'

  initializeOnClickListener: (onClick) ->
    body = document.getElementsByTagName("body")[0]
    attribute = 'data-obutton-click'
    mutationsListener = (mutations) ->
      for mutation in mutations
        if mutation.attributeName is attribute
          if body.hasAttribute(attribute) and body.getAttribute(attribute)?
            onClick JSON.parse(body.getAttribute attribute)
            body.removeAttribute(attribute)
            return
    new MutationObserver(mutationsListener).observe body,
      attributes: yes
      childList: no
      characterData: no

new OButtonCoreInPageContext().run()
