require 'mechanize'
require 'pry'

BASE_URL = 'https://www.sonypaymentservices.jp'
@all_links = ['https://www.sonypaymentservices.jp']
@outside_links = []
@error_links = []

agent = Mechanize.new

n = 0

loop do
  current_page = @all_links[n]
  break if current_page.nil?

  # Ignore pages which call outside url
  unless current_page.include?("sonypaymentservices.jp")
    @outside_links << current_page
    n += 1
    next
  end

  if current_page.start_with?("https://faq.sonypaymentservices.jp")
    n += 1
    next
  end

  puts "Get page: #{current_page}"
  page = agent.get(current_page)
  unless page.is_a?(Mechanize::Page)
    n += 1
    next
  end

  page_links = []
  page.links.each do |link|
    href = link.href

    # Ignore js href - ex: "#globalNavi", "tel:phone_number", "mailto:a@mail.com", "javascript:void(0)"
    next if href.nil? || href.start_with?("#") || href.start_with?("tel") || href.start_with?("mailto") || href.start_with?("javascript")

    link = if /https?:\/\/[\S]+/.match?(href)
             href
           else
             agent.resolve(href).to_s
           end

    page_links << link
  end

  @all_links += page_links.uniq.compact
  @all_links.uniq!
  puts "Total current links: #{@all_links.size}"

  n += 1
rescue Mechanize::ResponseCodeError, SocketError, Mechanize::UnsupportedSchemeError, URI::InvalidURIError => e
  puts "Error with page: #{current_page}"
  @error_links << current_page
  n += 1
  next
end

def export_md
  File.write("/Users/ttuan/Desktop/all_links.csv", @all_links.sort!.join(",\n"))
  File.write("/Users/ttuan/Desktop/outside_links.csv", @outside_links.sort!.join(",\n"))
  File.write("/Users/ttuan/Desktop/error_links.csv", @error_links.sort!.join(",\n"))
end
