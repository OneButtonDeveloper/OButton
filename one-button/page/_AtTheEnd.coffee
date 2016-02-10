# Script that will run at the end

if OButton?
  console.log 'OButton initialized in page scripts'

  firstTimeClick = {}
  for name, module of OButton
    firstTimeClick[name] = yes
    if module.initialize?
      try
        module.initialize()
        console.log "OButton.#{ name } initialized in page scripts"
      catch e
        console.log "OButton.#{ name } not initialized. See error: ", e

  onclick = ->
    console.log 'click in page scripts'
    for name, module of OButton
      if module.onceOnClick? and firstTimeClick[name]
        if not module.urlRegEx? or module.urlRegEx.test window.location.href
          console.log name + '.onceOnClick()'
          module.onceOnClick()
          firstTimeClick[name] = no
      if module.onClick?
        console.log name + '.onClick()'
        module.onClick()

  body = document.getElementsByTagName("body")[0]
  attribute = 'data-obutton-click'
  observer = new MutationObserver (mutations) ->
    for mutation in mutations
      if mutation.attributeName is attribute
        if body.hasAttribute(attribute) and body.getAttribute(attribute) is 'click'
          onclick()
          body.removeAttribute(attribute)
          return

  observer.observe body,
    attributes: yes
    childList: no
    characterData: no

else
  console.log 'OButton not initialized in page scripts'
