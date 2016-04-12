// ==UserScript==
// @name        BReminder
// @namespace   natuss
// @include     https://m.facebook.com/messages/read/?tid=mid.1392898855389%3Adcffa55c6ad7a24031&refid=11#fua
// @include     https://m.facebook.com/messages/read/?tid=mid.1392898855389%3Adcffa55c6ad7a24031&refid=12
// @version     1
// @grant       none
// ==/UserScript==


var info_frame = document.getElementById("root");
var active_time = info_frame.getElementsByTagName("span")[1];
var refresh_button = info_frame.getElementsByTagName("td")[0];

function makeNoti(){
  var options = {
    body: "Bí đang online. ^^",
    icon: "https://scontent-hkg3-1.xx.fbcdn.net/hprofile-xpa1/v/t1.0-1/c0.1.50.50/p50x50/12985573_1711615025720790_7974228556270884179_n.jpg?oh=963f9b3d8eda052eb8e01c0722d494fd&oe=57796F20",
  };

  var notification = new Notification("BReminder",options);
  notification.onclick = function () {
    window.open("https://www.fb.com/messages/dothihaianhhus");
  };

  var audio = new Audio("http://mp3.zing.vn/xml/load-song/MjAxMSUyRjA5JTJGMjMlMkZkJTJGZiUyRmRmZDBiOTJmZDM4N2Q5NjgyNGQ2NjhjYThhYTQ1MjM4Lm1wMyU3QzM=");
  audio.play();
}

function notifyMe() {
  if (!("Notification" in window)) {
    alert("This browser does not support desktop notification");
  }
  else if (Notification.permission === "granted") {
    makeNoti();
  }
  else if (Notification.permission !== 'denied') {
    Notification.requestPermission(function (permission) {
      if (!('permission' in Notification)) {
        Notification.permission = permission;
      }
      if (permission === "granted") {
        makeNoti();
      }
    });
  }
};

function reload_page() {
  setTimeout(function(){
       refresh_button.firstChild.click();
    }, 5000);
};

function recent_online(){
  return ((active_time.innerHTML.indexOf("second")> -1) || (active_time.innerHTML.indexOf("a minute") > -1))
}

setTimeout(function(){
  if (recent_online()){
    notifyMe();
  }
  reload_page();
}, 3000);

