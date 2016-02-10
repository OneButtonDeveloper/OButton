# Script that will run at the end

if OButton?
  console.log 'OButton initialized in content scripts'

  firstTimeClick = {}

  for name, module of OButton
    firstTimeClick[name] = yes
    if module.initialize?
      try
        module.initialize()
        console.log "OButton.#{ name } initialized in content scripts"
      catch e
        console.log "OButton.#{ name } not initialized. See error: ", e

  console.log 'kango.addMessageListener'
  kango.addMessageListener 'click', (event) =>
    try
      body = document.getElementsByTagName("body")[0]
      body.setAttribute('data-obutton-click', 'click')
      console.log 'click'
    catch e
      console.log 'click e', e

    for name, module of OButton
      if module.onceOnClick? and firstTimeClick[name]
        if not module.urlRegEx? or module.urlRegEx.test window.location.href
          console.log name + '.onceOnClick()'
          module.onceOnClick()
          firstTimeClick[name] = no
      if module.onClick?
        console.log name + '.onClick()'
        module.onClick()
else
  console.log 'OButton not initialized in content scripts'
