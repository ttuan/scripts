require "dotenv/load"
require "bundler"
Bundler.require

class VpsRequester
  BASE_URL = 'https://bgapi.vps.com.vn/handler'

  def vps_net_asset
    login

    {
      vps_normal: get_net_asset_value("#{ENV['VPS_ID']}1"),
      vps_margin: get_net_asset_value("#{ENV['VPS_ID']}6")
    }
  end

  def get_net_asset_value sub_account
    path = '/core.vpbs'
    url = BASE_URL + path

    body = Oj.generate({
      "group": "Q",
      "session": sid,
      "user": ENV["VPS_ID"],
      "data":{
        "type":"string",
        "cmd":"Web.Portfolio.AccountStatus",
        "p1": sub_account,
        "p2":"",
        "p3":"",
        "p4":"null"
      }
    })

    response = Faraday.post(url, body)
    response_body = Oj.load(response.body, symbol_keys: true)

    response_body[:data][:total_equity]
  end

  private
  attr_accessor :sid

  def login
    path = "/CheckLogin.aspx"
    url = BASE_URL + path

    data = {
      user: ENV["VPS_ID"],
      pass: ENV["VPS_PASSWORD"],
      channel: 'I',
      language: 'vi'
    }

    response = Faraday.post(url) do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(data)
    end

    response_body = Oj.load(response.body, symbol_keys: true)

    @sid = response_body[:data][:sid]
  end
end
