require 'open-uri'
require 'concurrent-ruby'

START_IMAGE_ID = 1
LATEST_IMAGE_ID = 141292 # 2021/09/22
CHUNK_SIZE = 50

BASE_URL = 'https://image.lgtmoon.dev/'

(START_IMAGE_ID..LATEST_IMAGE_ID).each_slice(CHUNK_SIZE) do |image_ids|
  puts "Download from #{image_ids.first} to #{image_ids.last}"

  promises = []

  image_ids.each do |image_id|
    promise = Concurrent::Promise.new do
      File.write "images/#{image_id}.png", open("#{BASE_URL}#{image_id}").read
    end

    promises << promise
  end

  promises.each(&:execute)
  Concurrent::Promise.zip(*promises).value
end
