# If have new chapter in blogtruyen.com, this tool will send message to your phone.
# You can use it to check whatever you want, like movies or news, .... if you know link and xpath to it
# All you need is a twilio account ;)

import requests
from lxml import html
import time
from twilio.rest import TwilioRestClient


# put you name of commic here. Link your commic is: http://blogtruyen.com/truyen/<ten-truyen>
list_comic_name = ['one-piece', 'conan']
host = 'http://blogtruyen.com/truyen/'
xpath = '//span[@class="publishedDate"]/text()'


def have_new_chapter(comic):
  page = requests.get(host + comic)
  tree = html.fromstring(page.content)

  published_date = tree.xpath(xpath)
  today = time.strftime("%d/%m/%Y")
  last_chapter_published_date = published_date[0].split(' ')[0]
  return today == last_chapter_published_date


def send_sms(list_comic_has_new_chap):
  # put your own credentials here
  account_sid = "Your twilio sid"
  auth_token = "Your twilio token"

  client = TwilioRestClient(account_sid, auth_token)
  client.messages.create(
      to="your mobile phone numbers",
      from_="your twilio phone number",
      body="Da co chapter moi truyen " + list_comic_has_new_chap + " vao doc thoi :v",
  )


def main():
  while(1):
    list_comic_has_new_chap = ""
    for comic_name in list_comic_name:
      if have_new_chapter(comic_name):
        list_comic_has_new_chap += comic_name + ','
    if list_comic_has_new_chap:
      send_sms(list_comic_has_new_chap)
      time.sleep(86400)
    else:
      time.sleep(3600)


if __name__ == '__main__':
  main()
