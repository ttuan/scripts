require 'net/http'
require 'uri'
require 'openssl'
require 'nokogiri'
require 'json'
require 'date'
require 'slack-ruby-client'
require 'concurrent-ruby'
require 'pry'

# Constants
SLACK_TOKEN="xoxb-xxxxx"
SLACK_CHANNEL="#zz-bot-notification"

ICONS = {
  "VN1Y" => "📉",
  "VN10Y" => "📈",
  "USDVND" => "💵",
  "DXY" => "💰",
  "Gold Price" => "🥇",
  "GD NDT NN" => "🌍",
  "VNINDEX" => "🇻🇳",
  "VN Gold Prices" => "🏅",
  "Brent Oil" => "⛽",
  "US10Y" => "📊",
  "ON" => "📰"
}.freeze

URLS = {
  "US10Y" => "https://tradingeconomics.com/united-states/government-bond-yield",
  "VN10Y" => "https://tradingeconomics.com/vietnam/government-bond-yield",
  "Brent Oil" => "https://tradingeconomics.com/commodity/brent-crude-oil",
  "Gold Price" => "https://tradingeconomics.com/commodity/gold",
  "VN Gold Prices" => "https://doji.vn/bang-gia-vang/",
  "GD NDT NN" => "https://cafef.vn/du-lieu/tracuulichsu2/3/hose/#{Date.today.strftime("%d/%m/%Y")}.chn",
  "VNINDEX" => "https://dstock.vndirect.com.vn/",
  "DXY" => "https://tradingeconomics.com/united-states/currency",
  "VN1Y" => "https://vn.investing.com/rates-bonds/vietnam-1-year-bond-yield-streaming-chart",
  "USDVND" => "https://tradingeconomics.com/usdvnd:cur",
  "ON" => "https://vira.org.vn/tin/Ban-tin.html"
}.freeze

# Abstract class for fetching financial data
class FinancialDataFetcher
  attr_reader :url, :symbol

  HEADERS = {
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
  }.freeze

  def initialize(url, symbol = nil)
    @url = url
    @symbol = symbol
  end

  def fetch_data
    raise NotImplementedError, "Subclasses must implement `fetch_data`"
  end

  protected

  def fetch_soup(verify: true)
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless verify

    request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
    response = http.request(request)
    return Nokogiri::HTML(response.body) if response.is_a?(Net::HTTPSuccess)

    nil
  rescue StandardError => e
    puts "Error fetching #{@url}: #{e}"
    nil
  end

  def convert_to_vnd_billion(amount)
    billion_vnd = amount.to_f / 1_000_000_000
    formatted = format('%.2f', billion_vnd)
    "#{formatted} tỷ"
  end
end

class TradingEconomicsFetcher < FinancialDataFetcher
  def fetch_data
    soup = fetch_soup
    return nil unless soup

    row = soup.at_css("tr[data-symbol='#{@symbol}']")
    return nil unless row

    price = row.at_css("td#p")&.text&.strip
    day_change = row.at_css("td#pch")&.text&.strip
    date_value = row.at_css("td#date")&.text&.strip
    return nil unless price && day_change && date_value

    "`#{price}`, Day Change: `#{day_change}` (#{date_value})"
  end
end

class Vietnam1YBondFetcher < FinancialDataFetcher
  def fetch_data
    soup = fetch_soup
    return nil unless soup

    yield_value = soup.at_css("div[data-test='instrument-price-last']")&.text&.strip
    change_percent = soup.at_css("span[data-test='instrument-price-change-percent']")&.text&.strip
    return nil unless yield_value && change_percent

    "`#{yield_value}`, Change: `#{change_percent.gsub(/[()]/, '')}`"
  end
end

# For ON interest
class MarketReportFetcher < FinancialDataFetcher
  BASE_URL = "https://vira.org.vn"

  def fetch_data
    soup = fetch_soup
    return nil unless soup

    today_date = Date.today.strftime("%d/%m/%Y")
    link = nil

    soup.css('.story__header').each do |header|
      meta_time = header.at_css('.story__meta time')

      if meta_time && meta_time.text.include?(today_date)
        header_text = header.text.strip

        if header_text.include?("Market Watch")
          relative_link = header.at_css('a')['href']
          link = URI.join(BASE_URL, relative_link).to_s
          break
        end
      end
    end

    if link.nil?
      puts "Market Watch link not found. Searching by title..."
      row_div = soup.at_css('.row')
      return nil unless row_div

      articles = row_div.css('article.story')
      return nil if articles.empty?

      articles.each do |article|
        title_tag = article.at_css('.story__title')
        if title_tag && title_tag.text.include?("Market Watch")
          link = URI.join(BASE_URL, title_tag.at_css('a')['href']).to_s
          break
        end
      end
    end

    return nil unless link

    @url = link
    new_soup = fetch_soup
    return nil unless new_soup

    money_market_section = new_soup.at_xpath("//ul[li[contains(normalize-space(.), 'MONEY MARKET')]]")

    if money_market_section
      next_p = money_market_section.at_xpath("following-sibling::p[1]")
      image = next_p.at_css("img") if next_p
      return image['src'] if image
    end

    "MONEY MARKET section not found."
  end
end

class VietnamGoldFetcher < FinancialDataFetcher
  def fetch_data
    soup = fetch_soup(verify: false)
    return nil unless soup

    prices = []
    taxonomy_blocks = soup.css("._taxonomy ._block")
    sell_blocks = soup.css("._Sell ._block")

    taxonomy_blocks.each_with_index do |block, index|
      if block.text.include?("SJC HN - Bán Lẻ")
        prices << "SJC HN - Bán Lẻ: `#{sell_blocks[index].text.strip}`"
      elsif block.text.include?("Nhẫn Tròn 9999")
        prices << "Nhẫn Tròn 9999: `#{sell_blocks[index].text.strip}`"
      end
      break if prices.size == 2
    end

    prices.any? ? prices.join(", ") : "No prices found."
  end
end

class VnindexFetcher < FinancialDataFetcher
  def fetch_data
    @url = "https://api-finfo.vndirect.com.vn/v4/vnmarket_prices?sort=date&q=code:VNINDEX"
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
    response = http.request(request)
    response_json = JSON.parse(response.body)
    data = response_json["data"]&.first

    return nil unless data

    close = data["close"]
    change = data["change"]
    volume = convert_to_vnd_billion(data["accumulatedVal"])
    date_time = "#{data['date']} #{data['time']}"
    parsed_date_time = DateTime.parse(date_time).strftime("%d/%m %H:%M")

    "`#{close}`, Change: `#{change}`, Volume: `#{volume}` (#{parsed_date_time})"
  end
end

class ForeignTransactionFetcher < FinancialDataFetcher
  def fetch_data
    today = Date.today.strftime("%m/%d/%Y")
    @url = "https://cafef.vn/du-lieu/Ajax/PageNew/DataGDNN/GDNuocNgoai.ashx?TradeCenter=HOSE&Date=#{today}"

    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
    response = http.request(request)
    response_json = JSON.parse(response.body)
    data = response_json["Data"]

    buy_value = convert_to_vnd_billion(data["BuyValue"])
    sell_value = convert_to_vnd_billion(data["SellValue"])
    diff_value = convert_to_vnd_billion(data["DiffValue"])

    return nil if buy_value == "0.00 tỷ" && sell_value == "0.00 tỷ" && diff_value == "0.00 tỷ"

    "Mua: `#{buy_value}`, Bán: `#{sell_value}`, Dif: `#{diff_value}` (#{Date.today.strftime('%b/%d')})"
  end
end

class SlackNotifier
  def initialize(token, channel)
    Slack.configure { |config| config.token = token }
    @client = Slack::Web::Client.new
    @channel = channel
  end

  def send_message(data)
    today_date = Time.now.strftime("%Y-%m-%d %H:%M")
    blocks = [{ type: "section", text: { type: "mrkdwn", text: "*Market Update - #{today_date}*" } }]

    data.each do |label, value|
      next unless value

      icon = ICONS.fetch(label, "📌")
      url = URLS.fetch(label, "#")
      linked_label = "<#{url}|#{label}>"

      text = "#{icon} *#{linked_label}*: #{value}"
      blocks << { type: "section", text: { type: "mrkdwn", text: text } }

      if label == "ON" && value.start_with?("http")
        blocks << {
          type: "image",
          image_url: value,
          alt_text: "Market Report"
        }
      end

      blocks << { type: "divider" } if label == "VN Gold Prices" or label == "VNINDEX"
    end

    @client.chat_postMessage(channel: @channel, blocks: blocks)
    puts "Slack message sent successfully."
  rescue Slack::Web::Api::Errors::SlackError => e
    puts "Error sending Slack message: #{e.message}"
  end
end

def fetch_concurrently(fetchers)
  futures = fetchers.map do |label, fetcher|
    [label, Concurrent::Future.execute { fetcher.fetch_data }]
  end.to_h

  futures.transform_values(&:value) # Blocking call to get all values
end

def run_market_update(slack_token, slack_channel)
  fetchers = {
    "US10Y" => TradingEconomicsFetcher.new(URLS["US10Y"], "USGG10YR:IND"),
    "VN10Y" => TradingEconomicsFetcher.new(URLS["VN10Y"], "VNMGOVBON10Y:GOV"),
    "Brent Oil" => TradingEconomicsFetcher.new(URLS["Brent Oil"], "CO1:COM"),
    "Gold Price" => TradingEconomicsFetcher.new(URLS["Gold Price"], "XAUUSD:CUR"),
    "VN Gold Prices" => VietnamGoldFetcher.new(URLS["VN Gold Prices"]),
    "GD NDT NN" => ForeignTransactionFetcher.new(URLS["GD NDT NN"]),
    "VNINDEX" => VnindexFetcher.new(URLS["VNINDEX"]),
    "DXY" => TradingEconomicsFetcher.new(URLS["DXY"], "DXY:CUR"),
    "VN1Y" => Vietnam1YBondFetcher.new(URLS["VN1Y"]),
    "USDVND" => TradingEconomicsFetcher.new(URLS["USDVND"], "USDVND:CUR"),
    "ON" => MarketReportFetcher.new(URLS["ON"])
  }

  market_data = fetch_concurrently(fetchers)

  slack_notifier = SlackNotifier.new(slack_token, slack_channel)
  slack_notifier.send_message(market_data)
end

run_market_update(SLACK_TOKEN, SLACK_CHANNEL)
