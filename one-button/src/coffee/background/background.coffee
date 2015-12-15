  kango.ui.browserButton.addEventListener kango.ui.browserButton.event.COMMAND, ->
    kango.browser.tabs.getCurrent (tab) -> tab.dispatchMessage 'click', content: 'click'