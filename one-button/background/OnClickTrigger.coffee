kango.ui.browserButton.addEventListener kango.ui.browserButton.event.COMMAND, ->
  kango.browser.tabs.getCurrent (tab) -> tab?.dispatchMessage 'click',
    eventType: 'click' # any object that will come in "dataFromBackground" of onClick()
