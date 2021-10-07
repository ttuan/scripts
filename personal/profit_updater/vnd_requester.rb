require "dotenv/load"
require "bundler"
Bundler.require

class VndRequester

  def vnd_net_asset
    login

    {
      vndirect: get_net_asset_value("#{ENV['VND_ACCOUNT']}"),
    }
  end

  def get_net_asset_value account
    url = "https://trade-bo-api.vndirect.com.vn/accounts/v3/#{account}/assets"

    headers = {
      'X-Auth-Token' => @token
    }
    response = Faraday.get(url, {}, headers)
    response_body = Oj.load(response.body, symbol_keys: true)

    response_body[:netAssetValue].to_i
  end

  private
  attr_accessor :token

  def login
    url = "https://auth-api.vndirect.com.vn/v3/auth?t=#{Time.now.to_i}"

    body = {
      username: ENV["VND_USERNAME"],
      password: ENV["VND_PASSWORD"],
    }

    response = Faraday.post(url, body)
    response_body = Oj.load(response.body, symbol_keys: true)

    @token = response_body[:token]
  end
end
