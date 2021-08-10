// ==UserScript==
// @name         qwiklabs remove sidebar
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       ttuan
// @match        https://www.qwiklabs.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    var left_sidebar = document.getElementById("control-panel-drawer");
    var right_sidebar = document.getElementById("outline-drawer");
    left_sidebar.remove();
    right_sidebar.remove();

    var content_block = document.querySelector("#lab-content-container").shadowRoot.querySelector(".content");
    content_block.style.margin = "0px 0px";
})();
