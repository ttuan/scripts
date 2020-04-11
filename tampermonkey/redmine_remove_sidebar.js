// ==UserScript==
// @name         Redmine remove sidebar
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://dev.sun-asterisk.com/projects/trill-dely/issues*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    // Remove sidebar
    var sidebar = document.getElementById("sidebar");
    sidebar.parentNode.removeChild(sidebar);

    // Extend content
    var content = document.getElementById("content");
    content.style.width = "100%";
})();
