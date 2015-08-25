__author__ = 'tuan'

# Be the change you want to see in the world


# This tool help you download mp3 file in some host: mp3.zing.vn, chiasenhac.com, nhaccuatui.com,...
# You can change default host(which I set 'chiasenhac.com') to what you want :D
# GUI will come soon

import urllib
import json
import os
import sys
code = "db869e61-daff-4536-967b-2e0b87feef75"
default_host = "chiasenhac.com"

def download_datafile(name, host):
    if not host:
        host = default_host
    song = urllib.urlopen("http://j.ginggong.com/jOut.ashx?k=%s&h=%s&code=%s" % (name, host, code))
    f = 'data.json'
    output = open(f, "wb")
    output.write(song.read())
    output.close()


def read_file():
    with open("data.json") as data_file:
        data = json.load(data_file)
    if not data:
        print "Sorry, We cannt find this song for you"
        os.remove("data.json")
        sys.exit(0)
    return data[0]["UrlJunDownload"], data[0]["Title"]


def download_song():
    url, name = read_file()
    saved_folder = os.path.join(os.path.expanduser('~'), 'Downloads', 'Mp3Downloads')
    if not os.path.exists(saved_folder):
        os.makedirs(saved_folder)
    song_name = os.path.join(saved_folder, '%s.mp3' % name)
    print "Downloading......................................................"
    urllib.urlretrieve(url, song_name)
    os.remove("data.json")
    print "Done. Go to /Downloads/Mp3Downloads to listen this song :D"


def input_data():
    name = ""
    while not name:
        name = raw_input("Enter the name song: ")
    name += raw_input("Enter the singer, find all singer if blank: ")
    host = raw_input("Enter the website to download, find all web if blank: ")
    return name, host


def main():
    name, host = input_data()
    download_datafile(name, host)
    read_file()
    download_song()


if __name__ == '__main__':
    main()
