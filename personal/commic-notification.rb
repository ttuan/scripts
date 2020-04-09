#!/bin/ruby

require 'mechanize'
require 'chatwork'

BASE_URL = 'http://2.truyentranhmoi.com/'
CHATWORK_TOKEN = "xxxxx"
@mechanize = Mechanize.new
@client = ChatWork::Client.new(api_key: CHATWORK_TOKEN)

ITEMS = {
  'tay-du': {users: [1385539, 1308582, 1327803], last_sent: DateTime.now.to_s},
  'prison-school': {users: [1308582], last_sent: DateTime.now.to_s},
  'tower-of-god-2': {users: [1308582], last_sent: DateTime.now.to_s},
  'the-gamer': {users: [1308582], last_sent: DateTime.now.to_s},
  'one-piece-dao-hai-tac': {users: [1308582], last_sent: DateTime.now.to_s},
  'hiep-khach-giang-ho': {users: [1308582], last_sent: DateTime.now.to_s},
  'hunter-x-hunter': {users: [1308582], last_sent: DateTime.now.to_s},
  'berserk': {users: [1308582], last_sent: DateTime.now.to_s},
  'kengan-ashua': {users: [1327803], last_sent: DateTime.now.to_s},
  'hoa-phung-lieu-nguyen': {users: [1327803], last_sent: DateTime.now.to_s},
  'kingdom-vuong-gia-thien-ha': {users: [1327803], last_sent: DateTime.now.to_s},
  'shokugeki-no-soma-vua-bep-soma': {users: [1327803], last_sent: DateTime.now.to_s},
  'onepunch-man': {users: [1327803], last_sent: DateTime.now.to_s},
}

def check_new_chapter
  ITEMS.each do |k, v|
    page = @mechanize.get(BASE_URL + k.to_s)
    lastest_chap = page.search(".chap-list ul li")[0]
    chapter_name = lastest_chap.search("a").text
    chapter_date = DateTime.parse lastest_chap.search("p")[0].text.split(":")[1]
    updated_time = updated_at(page.search(".date.updated").text.split(" "), v)
    if chapter_date > DateTime.parse(v[:last_sent]) || updated_time > DateTime.parse(v[:last_sent])
      notify_chatwork v[:users], chapter_name, lastest_chap.search("a")[0]["href"], chapter_date
    end
    v[:last_sent] = updated_time.to_s
  end
end

def notify_chatwork users, chapter_name, link, chapter_date
  @contacts ||= @client.get_contacts
  followers = @contacts.select {|x| users.include?(x[:account_id])}
  followers.each do |f|
    body = <<~HEREDOC
      [To:#{f[:account_id]}] #{f[:name]}
      Đã có #{chapter_name} (đăng ngày #{chapter_date}) tại : #{link}
    HEREDOC
    @client.create_message(room_id: f[:room_id], body: body)
  end
end

def updated_at time, v
  if time[1] == "giờ"
    DateTime.parse (DateTime.now - time[0].to_i / 24.0).strftime("%Y-%m-%d %H")
  else
    DateTime.parse(v[:last_sent])
  end
end

while true do
  check_new_chapter
  sleep(30 * 60)
end
