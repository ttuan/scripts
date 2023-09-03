# Download transactions from Vietcombank to file xlsx
# Edit this file manually to choose which transactions should be imported
# Read file and import to Money Lover with this command:
# ruby import_transaction_to_money_lover.rb transactions.xlsx

require "roo"
require "watir"
require "faraday"

class MoneyLoverOperator
  attr_accessor :access_token

  BASE_URL = 'https://web.moneylover.me'

  ML_ACCOUNT_EMAIL = ENV["ML_ACCOUNT_EMAIL"]
  ML_ACCOUNT_PASSWORD = ENV["ML_ACCOUNT_PASSWORD"]
  ML_WALLET_ID = ENV["ML_WALLET_ID"]

  def bulk_import transactions
    transactions_path = "/api/transaction/add"
    url = BASE_URL + transactions_path
    headers = {
      "Authorization" => "AuthJWT #{fetch_token}",
      "Content-Type" => "application/json"
    }

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
        body = JSON.dump({
          "with": [],
          "account": ML_WALLET_ID,
          "category": category[:_id],
          "amount": transaction[:amount],
          "note": note,
          "displayDate": transaction[:displayDate],
          "event": "",
          "exclude_report": false,
          "longtitude": 0,
          "latitude": 0,
          "addressName": "",
          "addressDetails": "",
          "addressIcon": "",
          "image": ""
        })

        response = Faraday.post(url, body, headers)
        data = JSON.parse(response.body, symbolize_names: true)

        ignored_transactions << transaction unless data[:error] == 0
      end
    end

    # Write ignored transactions to file csv
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

    categories_path = "/api/category/list-all"
    url = BASE_URL + categories_path
    headers = {
      Authorization: "AuthJWT #{fetch_token}"
    }

    response = Faraday.post(url, {}, headers)
    all_categories = JSON.parse(response.body, symbolize_names: true)[:data]
    @categories = all_categories.select { |category| category[:account] == ML_WALLET_ID }
  end

  def fetch_token
    return @access_token if @access_token

    browser = Watir::Browser.new :chrome, options: {args: %w[--headless --no-sandbox --disable-dev-shm-usage --disable-gpu --remote-debugging-port=9222]}
    service_url = "https://web.moneylover.me/"
    browser.goto service_url

    # Wait util redirect success and get token
    sleep(5)
    token = browser.url.split("token=")[1].split("&")[0]

    headers = {
      Authorization: "Bearer #{token}",
      client: "kHiZbFQOw5LV"
    }

    oauth_url = "https://oauth.moneylover.me/token"
    body = {"email": ML_ACCOUNT_EMAIL, "password": ML_ACCOUNT_PASSWORD }

    response = Faraday.post(oauth_url, body, headers)
    data = JSON.parse(response.body, symbolize_names: true)
    @access_token = data[:access_token]

    @access_token
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
