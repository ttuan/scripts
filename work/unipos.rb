require "rest-client"
require "pry"

class Unipos
  SETTINGS = {
    email: "tran.van.tuan@framgia.com",
    password: "sxz7jvXp36KM",
    members: {
      "nguyen.ngoc.truong": 50,
      "nguyen.tan.duc": 50,
      "hoang.minh.tuan": 50,
      "nguyen.thi.men": 50,
      "pham.thi.van.anh": 50,
      "lim.kimhuor": 50,
      "le.quang.canh": 50,
      "nguyen.tien.trung": 50
    },
    hash_tags: [
      "#1.AppreciateTeamwork",
      "#2.ThinkOutsideTheBox",
      "#3.HaveTheGutsToChallenge",
      "#4.ThinkPositive",
      "#5.SpeedUp",
      "#6.BeProfessional",
      "#7.FocusOnThePoint"
    ],
    messages: [
      "I know you have tried your best in this year. Good luck "
    ]
  }

  ENDPOINTS = {
    login: "https://unipos.me/a/jsonrpc",
    search_person: "https://unipos.me/q/jsonrpc",
    send_point: "https://unipos.me/c/jsonrpc"
  }

  def initialize
    @auth_token = get_auth_token
  end

  def execute
    SETTINGS[:members].each do |member_name, point|
      member_id = get_member_id member_name
      send_point member_id, point
    end
  end

  private
  attr_reader :auth_token

  def get_auth_token
    login_params = {
      jsonrpc: "2.0",
      method: "Unipos.Login",
      params: {
        email_address: SETTINGS[:email],
        password: SETTINGS[:password]
      },
      id: "Unipos.Login"
    }

    response = RestClient.post(ENDPOINTS[:login], login_params.to_json, content_type: :json)

    JSON.parse(response.body)["result"]["authn_token"]
  end

  def get_member_id member_name
    search_person_params = {
      jsonrpc: "2.0",
      method: "Unipos.FindSuggestMembers",
      params: {
        term: member_name,
        limit: 20
      },
      id: "Unipos.FindSuggestMembers"
    }

    search_response = RestClient.post(
      ENDPOINTS[:search_person],
      search_person_params.to_json,
      headers = {
        content_type: :json,
        "x-unipos-token": auth_token
      })

    JSON.parse(search_response.body)["result"].first["id"]
  end

  def send_point member_id, point
    send_point_params = {
      jsonrpc: "2.0",
      method: "Unipos.SendCard",
      params: {
        from_member_id: "",
        to_member_id: member_id,
        point: point,
        message: SETTINGS[:hash_tags].sample + " " + SETTINGS[:messages].sample
      },
      id: "Unipos.SendCard"
    }

    RestClient.post(
      ENDPOINTS[:send_point],
      send_point_params.to_json,
      headers = {
        content_type: :json,
        "x-unipos-token": auth_token
      })
  end
end

Unipos.new.execute
