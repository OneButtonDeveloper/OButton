# Script that will run at the end

if OButton
  console.log 'OButton initialized'

  for name, module of OButton
    console.log "OButton.#{ name } initialized"
    module.initialize?()

  isFirstTimeClick = yes

  console.log 'kango.addMessageListener'
  kango.addMessageListener 'click', (event) =>
    console.log 'click'
    for name, module of OButton
      console.log 'Module.click:', name, module
      module.onceOnClick?() if isFirstTimeClick
      module.onClick?()
    isFirstTimeClick = false
else
  console.log 'OButton not initialized'

