require 'json'
require 'faraday'
require 'slack_mrkdwn'

class GithubTrending
  TRENDING_URL = {
    all: "https://api.github.com/repos/vitalets/github-trending-repos/issues/6/comments",
    ruby: "https://api.github.com/repos/vitalets/github-trending-repos/issues/9/comments"
  }

  def perform
    TRENDING_URL.each do |language, url|
      response = Faraday.get(url)
      comments = JSON.parse(response.body, symbolize_names: true)

      today_comment = comments.last
      trending_repos = today_comment[:body]

      message = trending_repos
      slack_forward message
    end
  end

  private
  def slack_forward message
    headers = {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json',
      'Api-Key' => 'oppa_api_key',
      'Authorization' => 'Basic oppa_basic_auth'
    }

    body = {
      conversation: "slack_converstaion_id",
      message: SlackMrkdwn.from(message),
      ts: "slack_thread_id"
    }.to_json

    response = Faraday.post('https://oppa.sun-asterisk.vn/forwarder', body, headers)
  end
end

GithubTrending.new.perform
