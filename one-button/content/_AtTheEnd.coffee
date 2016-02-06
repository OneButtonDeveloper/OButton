# Script that will run at the end

if OButton?
  console.log 'OButton initialized'

  firstTimeClick = {}

  for name, module of OButton
    firstTimeClick[name] = yes
    if module.initialize?
      module.initialize()
      console.log "OButton.#{ name } initialized"

  console.log 'kango.addMessageListener'
  kango.addMessageListener 'click', (event) =>
    console.log 'click'
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
  console.log 'OButton not initialized'
