require "slackdown"
require "faraday"

class CleanCodeRuby
  CLEAN_CODE_RUBY_DATA = "./work/data/clean_code_ruby.md"
  SLACK_CHANNEL = "channel_id"

  OPPA_ENDPOINT = "https://oppa.sun-asterisk.vn/forwarder"
  OPPA_BASIC_AUTH = "oppa_basic_auth"
  OPPA_API_KEY = "oppa_api_key"

  def perform
    content = File.read(CLEAN_CODE_RUBY_DATA)

    sections = content.split(/(?=^###\s)/)
    tip_of_the_day = sections.sample

    slack_forward tip_of_the_day
  end

  private
  def slack_forward message
    headers = {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "Api-Key" => OPPA_API_KEY,
      "Authorization" => OPPA_BASIC_AUTH
    }

    body = {
      conversation: SLACK_CHANNEL,
      message: Slackdown.convert(message),
    }.to_json

    response = Faraday.post(OPPA_ENDPOINT, body, headers)
    p response.body
  end
end

CleanCodeRuby.new.perform

