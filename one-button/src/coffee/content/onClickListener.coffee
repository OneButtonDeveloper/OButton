kango.addMessageListener 'click', (event) ->

  { oneButton } = window
  unless oneButton
    console.log 'oneButton not initialized'
    return
  
  for name, extension of oneButton.extension()
    extension.onClick?()

  return null