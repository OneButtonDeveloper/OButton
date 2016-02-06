#require shortcut

((LorenIpsum) ->

  class Randomizer
    meat: ['alcatra', 'amet', 'andouille', 'bacon', 'ball', 'beef', 'belly', 'biltong', 'boudin', 'bresaola', 'brisket', 'capicola', 'chicken', 'chop', 'chuck', 'corned', 'cow', 'cupim', 'dolor', 'doner', 'drumstick', 'fatback', 'filet', 'flank', 'frankfurter', 'ground', 'ham', 'hamburger', 'hock', 'ipsum', 'jerky', 'jowl', 'kevin', 'kielbasa', 'landjaeger', 'leberkas', 'loin', 'meatball', 'meatloaf', 'mignon', 'pancetta', 'pastrami', 'picanha', 'pig', 'porchetta', 'pork', 'prosciutto', 'ribeye', 'ribs', 'round', 'rump', 'salami', 'sausage', 'shank', 'shankle', 'short', 'shoulder', 'sirloin', 'spare', 'steak', 'strip', 'swine', 't-bone', 'tail', 'tenderloin', 'tip', 'tongue', 'tri-tip', 'turducken', 'turkey', 'venison']
    getMeat: =>
      return @meat[Math.floor(Math.random()*@meat.length)]
    @get: =>
      @randomizer ?= new Randomizer()

  LorenIpsum.initialize = ->
    #git_commits_box  = require('./html/commits_box.html')
    shortcut = require('exports?shortcut!./libs/shortcut.js')

    handlers = {}
    handlers.input = ($el) ->
      $el.val Randomizer.get().getMeat()

    shortcut.add "Alt+F1", ->
      if el = document.activeElement
        handlers[el.tagName.toLowerCase()]? $ el

)(OButton.LorenIpsum ?= {})
