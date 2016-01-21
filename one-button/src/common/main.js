// ==UserScript==
// @name one-button
// @include http://*
// @include https://*
// @include about:blank
// @require libs/jquery.min.js
// @require libs/handlebars.min.js
// @require libs/shortcut.js
// ==/UserScript==

var $ = window.$.noConflict(true); // Required for IE

// console.log('Main.js: JQuery ' + $.fn.jquery  + ' Handlebars: ' + Handlebars.VERSION);