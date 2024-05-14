# Download transactions from Vietcombank to file xlsx
# Edit this file manually to choose which transactions should be imported
# Read file and import to Money Lover with this command:
# ruby import_transaction_to_money_lover.rb transactions.xlsx

require "faraday"
require "roo"
require "json"

class MoneyLoverOperator
  attr_accessor :access_token

  ML_ACCOUNT_EMAIL = ENV["ML_ACCOUNT_EMAIL"]
  ML_ACCOUNT_PASSWORD = ENV["ML_ACCOUNT_PASSWORD"]
  ML_WALLET_ID = ENV["ML_WALLET_ID"]

  DEFAULT_HEADERS = {
    "client" => "lzruIoplt7I9",
    "appversion" => "7021",
    "apiVersion" => "4",
    "User-Agent" => "MoneyLoverFree/7.21.2 (iPhone; iOS 17.0; Scale/3.00)",
  }

  def bulk_import transactions
    transaction_url = "https://revoapi.moneylover.me/api/sync/push/transaction/v2"
    headers = {
      "Authorization" => "Bearer #{fetch_token}",
      "Content-Type" => "application/json",
    }.merge(DEFAULT_HEADERS)
    ignored_transactions = []

    puts "=========== Import to Money Lover ==========="
    transactions.each.with_index(1) do |transaction, index|
      category_name, note = transaction[:note].split(":: ")
      category = categories.find { |category| category[:name] == category_name }

      puts "=========== Importing #{index}/#{transactions.size} ==========="
      puts "Notes: #{transaction[:note]}"

      if category.nil?
        ignored_transactions << transaction
      else
        data = JSON.dump({
          "d" => [
            {
              "lo"=>0, # Longitude
              "ad"=>"", # Address
              "la"=>0, # Latitude
              "oc"=>"",
              "a"=> transaction[:amount], # amount
              "ac"=> ML_WALLET_ID, # wallet id
              "pi"=>"",
              "v"=>0,
              "c"=> category[:_id], # category id
              "gid"=> SecureRandom.uuid, # Transaction id
              "mr"=>false,
              "er"=>false, # exclude report
              "dd"=> transaction[:displayDate], # display date
              "rd"=>0,
              "n"=> note, # note
              "f"=>1,
              "im"=>[] # image
            }
          ]
        })
        body = JSON.dump({
          "pl" => 2, # platform
          "data" => data,
          "av" => 7021, # app version
        })

        response = Faraday.post(transaction_url, body, headers)
        data = JSON.parse(response.body, symbolize_names: true)

        ignored_transactions << transaction if data[:failedItems].any?
      end
    end

    return if ignored_transactions.empty?

    File.open("ignored_transactions.csv", "w") do |f|
      ignored_transactions.each do |transaction|
        f.puts "#{transaction[:displayDate]},#{transaction[:amount]},#{transaction[:note]}"
      end
    end
  end


  private
  def categories
    return @categories if @categories

    category_url = "https://revoapi.moneylover.me/api/sync/pull/category/v2"
    headers = {
      "Authorization": "Bearer #{fetch_token}",
      "Content-Type" => "application/json",
    }.merge(DEFAULT_HEADERS)
    all_categories = []
    skip = 0
    while true
      body = JSON.dump({
        "last_update" => 0,
        "limit" => 80,
        "skip" => skip
      })
      response = Faraday.post(category_url, body, headers)
      response_data = JSON.parse(response.body, symbolize_names: true)
      all_categories += response_data[:data]

      break if response_data[:data].size == 0
      skip += 80
    end

    @categories = all_categories.select { |category| category[:account][:_id] == ML_WALLET_ID }
  end

  def fetch_token
    return @access_token if @access_token

    # Request token
    headers = {
      "Authorization": "Basic bHpydUlvcGx0N0k5OllQcURIZ0kzbVJiMVlkdjRmbzBUcEMyUnc3ZFZHcA==",
      "Content-Type" => "application/x-www-form-urlencoded"
    }.merge(DEFAULT_HEADERS)

    response = Faraday.post("https://oauth.moneylover.me/request-token", {}, headers)
    data = JSON.parse(response.body, symbolize_names: true)
    request_token = data[:request_token]

    # Request access_token
    headers = {
      Authorization: "Bearer #{request_token}",
      client: "lzruIoplt7I9",
    }
    body = {
      "email": ML_ACCOUNT_EMAIL,
      "password": ML_ACCOUNT_PASSWORD,
      "purchased": true,
      "grant_type": "password"
    }
    response = Faraday.post("https://oauth.moneylover.me/token", body, headers)
    data = JSON.parse(response.body, symbolize_names: true)
    @access_token = data[:access_token]
  end
end

class Transaction
  START_ROW = 13

  def self.transactions file_name
    puts "=========== Read transactions from file ==========="
    transactions = []
    xlsx = Roo::Spreadsheet.open(file_name)

    xlsx.each_row_streaming(offset: 13) do |row|
      # End if row is empty
      break if row.all? { |cell| cell.value.nil? }

      if row[0].value.nil?
        row = row.drop(1)
      end

      transaction = {}

      date = row[1].value.split("\n")[0].split("/")
      transaction[:displayDate] = "#{date[2]}-#{date[1]}-#{date[0]}"
      transaction[:amount] = row[2].value.nil? ? nil : row[2].value.gsub(",", "").to_i
      transaction[:note] = row[5].value

      transactions << transaction
    end

    puts "=========== Read transactions done ==========="
    transactions
  end
end

# Read args from command line to get file name
file_name = ARGV[0]

transactions = Transaction.transactions(file_name)
MoneyLoverOperator.new.bulk_import(transactions)
