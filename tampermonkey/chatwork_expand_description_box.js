// ==UserScript==
// @name         Chatwork Expand description box
// @namespace    chatwork
// @version      0.1
// @description  Expand description box for Chatwork
// @author       ttuan
// @match        https://www.chatwork.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';
    setTimeout(function() {
        var expandButton = document.createElement("BUTTON");
        expandButton.innerHTML = "&darr;";
        expandButton.onclick = function() {document.getElementById('_subRoomDescriptionWrapper').style.height = '400px'; }
        document.getElementsByClassName("roomDescription__headerText")[0].appendChild(expandButton);
    }, 3000)
})();
