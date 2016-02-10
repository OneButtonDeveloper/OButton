((LorenIpsum) ->

  contains = (text, array) ->
    for item in array
      if text.indexOf(item) >= 0 then return true
    false

  class Randomizer
    meat: ['alcatra', 'amet', 'andouille', 'bacon', 'ball', 'beef', 'belly', 'biltong', 'boudin', 'bresaola', 'brisket', 'capicola', 'chicken', 'chop', 'chuck', 'corned', 'cow', 'cupim', 'dolor', 'doner', 'drumstick', 'fatback', 'filet', 'flank', 'frankfurter', 'ground', 'ham', 'hamburger', 'hock', 'jerky', 'jowl', 'kevin', 'kielbasa', 'landjaeger', 'leberkas', 'loin', 'meatball', 'meatloaf', 'mignon', 'pancetta', 'pastrami', 'picanha', 'pig', 'porchetta', 'pork', 'prosciutto', 'ribeye', 'ribs', 'round', 'rump', 'salami', 'sausage', 'shank', 'shankle', 'short', 'shoulder', 'sirloin', 'spare', 'steak', 'strip', 'swine', 't-bone', 'tail', 'tenderloin', 'tip', 'tongue', 'tri-tip', 'turducken', 'turkey', 'venison']
    constructor: ->
      @upperMeat = for meat in @meat
        meat[0].toUpperCase() + meat.substr(1)
    randomFromArray: (array) ->
      array[Math.floor(Math.random()*array.length)]
    randomBool: -> Math.random() < 0.5
    getMeat: -> @randomFromArray @meat
    getUpperMeat: => @randomFromArray @upperMeat


  LorenIpsum.initialize = ->
    shortcut = require('exports?shortcut!./libs/shortcut.js')
    randomizer = new Randomizer()
    handlers = {}
    handlers.input = ($el, id, altKey) ->
      if $el.attr('type') is 'checkbox'
        return $el.prop 'checked', randomizer.randomBool()
      if ($el.attr('class') ? '').indexOf('select2') >= 0
        $select = $('#' + id.replace('_search', '')).parent().next('select')
        if $select.length > 0
          return handlers['select']($select, $select.attr('id').toLowerCase(), altKey)
      inputHandlers = [
        ($el, id, altKey) ->
          if contains(id, ['firstname', 'lastname'])
            return randomizer.getUpperMeat() + ' ' + randomizer.getUpperMeat()
        ($el, id, altKey) ->
          if contains(id, ['phone', 'mobile'])
            return '+4722222222'
        ($el, id, altKey) ->
          if contains(id, ['date', 'period'])
            if contains(id, ['from', 'start'])
              return '01.01.2016'
            if contains(id, ['to', 'end'])
              return '31.12.2016'
            return '03.04.1991'
        ($el, id, altKey) ->
          if contains(id, ['email', 'mail'])
            return 'one.button.developer@gmail.com'
        ($el, id, altKey) ->
          if contains(id, ['percent', 'quantity'])
            return 24
        ($el, id, altKey) ->
          if contains(id, ['price', 'cost', 'salary', 'rate', 'sum', 'amount'])
            return 1000
        ($el, id, altKey) ->
          if contains(id, ['site'])
            return 'www.google.com'
        ($el, id, altKey) ->
          if contains(id, ['time'])
            return '1:30'
        ($el, id, altKey) ->
          if contains(id, ['url', 'link'])
            return 'URL??'
        ($el, id, altKey) ->
          if contains(id, ['user', 'person'])
            return randomizer.getUpperMeat() + ' ' + randomizer.getUpperMeat()
        ($el, id, altKey) ->
          if contains(id, ['number', 'size'])
            return 123456
        ($el, id, altKey) ->
          if contains(id, ['name', 'title'])
            return randomizer.getUpperMeat() + ' ' + randomizer.getMeat()
        ($el, id, altKey) ->
          randomizer.getUpperMeat()
      ]
      for handler in inputHandlers
        if value = handler $el, id, altKey
          $el.val(value).change()
          return
    handlers.select = ($el, id, altKey) ->
      childrens = $el.children()
      if childrens.length > 0
        $randomChild = $(randomizer.randomFromArray(childrens))
        newValue = $randomChild.attr('value') ? null
        if childrens.length is 1 and not newValue? then return
        $el.attr('data-value', newValue).val(newValue).change()
        $el.select2?('val', newValue)

    handlers.textarea = ($el, id, altKey) ->
      $el.val('Very long long long long long long long long long long long long long text...').change()

    keydown = (e) ->
      if (e.key is 'Tab' or e.keyCode is 9 or e.which is 9) and (el = document.activeElement)
          $el = $(el)
          id = ($el.attr('id') ? '').toLowerCase()
          handlers[el.tagName.toLowerCase()]? $(el), id, e.altKey

    isActive = true
    $(document).on 'keydown', keydown
    shortcut.add "Alt+F1", ->
      $(document)[if isActive then 'off' else 'on'] 'keydown', keydown
      isActive = not isActive

)(OButton.LorenIpsum ?= {})