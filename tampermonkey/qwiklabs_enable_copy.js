// ==UserScript==
// @name         qwiklabs enable copy
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.qwiklabs.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    var element = document.getElementById("markdown-lab-instructions");
    element.classList.remove("no-select");
})();
