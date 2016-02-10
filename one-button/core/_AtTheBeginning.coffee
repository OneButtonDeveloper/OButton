# Script that will run at the beginning

defineOButton = (contextName) ->
  # initialization of a OButton
  window.OButton ?= {}
  console.log "OButton defined in a #{contextName} context"

  # TODO: made polifill for keys() function
  window.requireAll = (r) -> r.keys().forEach(r)

module.exports = defineOButton
