# Script that will run at the beginning

# initialization of a OButton
window.OButton ?= {}
console.log 'OButton initialized in content scripts'

# TODO: made polifill for keys() function
window.requireAll = (r) -> r.keys().forEach(r)
