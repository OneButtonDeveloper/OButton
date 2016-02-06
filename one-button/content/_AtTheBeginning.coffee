# Script that will run at the beginning

# Global libs that will be available in all modules
# require jquery.min

# initialization of a OButton
window.OButton ?= {}

window.$ = window.$.noConflict(true)

# TODO: made polifill for keys() function
window.requireAll = (r) ->
  r.keys().forEach(r)

console.log 'JQuery ' + $.fn.jquery
