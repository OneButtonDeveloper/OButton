# Script that will run at the beginning

# Global libs that will be available in all modules
#require jquery.min
#require handlebars.min

# initialization of a OButton
window.OButton ?= {}

window.$ = window.$.noConflict(true)

console.log 'Main.js: JQuery ' + $.fn.jquery + ' Handlebars: ' + Handlebars.VERSION