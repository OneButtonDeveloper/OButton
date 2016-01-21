# initialization of a oneButton extensions cache
unless window.oneButton
  oneButton = {}
  oneButton.extension = (->
    extensions = {}
    (name) ->
      if name
        extensions[name] ?= {}
      else
        extensions
  )()
  window.oneButton = oneButton