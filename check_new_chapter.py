# If have new chapter in blogtruyen.com, this tool will send message to your phone.
# You can use it to check whatever you want, like movies or facebook message, .... if you know link and xpath to it
# All you need is a twilio account ;)

import requests
from lxml import html
import time
from twilio.rest import TwilioRestClient


# put your link of comic in blogtruyen here
link_comic = 'http://blogtruyen.com/truyen/conan'
xpath = '//span[@class="publishedDate"]/text()'


def have_new_chapter():
    page = requests.get(link_comic)
    tree = html.fromstring(page.content)

    published_date = tree.xpath(xpath)
    today = time.strftime("%d/%m/%Y")
    last_chapter_published_date = published_date[0].split(' ')[0]
    return today == last_chapter_published_date


def send_sms():
    # put your own credentials here
    account_sid = "YOUR TWILIO SID"
    auth_token = "YOUR TWILIO TOKEN"

    client = TwilioRestClient(account_sid, auth_token)
    client.messages.create(
        to="your mobile phone number",
        from_="your phone number in twilio",
        body="Have new chapter, please read it ;)",
    )


def main():
    if have_new_chapter():
        send_sms()
        time.sleep(86400)

if __name__ == '__main__':
    main()
