require 'mechanize'
require 'csv'
require 'pry'
require 'fileutils'

BASE_URL = 'http://testing_site.vn/'
@mechanize = Mechanize.new

def links
  page = @mechanize.get(BASE_URL)
  links = page.search(".dropdown-menu-cat li a").map {|link| link.attribute("href").text}
  binding.pry
end

def crawler page_name
  page = @mechanize.get(BASE_URL + page_name)
  results = []

  loop do
    products = page.search(".product-item")
    products.each do |product|
      name = product.search(".product-name a").text.strip
      brand = product.search(".product-brand a").text.strip
      market_price = product.search(".product-price-old").text.strip
      sell_price = product.search(".product-price-new").text.strip
      image = product.search(".product-thumb .img-responsive").attribute("src").text
      selloff = product.search(".product-flag").text.strip
      infos = []

      product.search(".product-short-data p").each_with_index do |p, i|
        infos[i] = p.text.strip.split(":")[1]
      end

      results << [name, brand, market_price, sell_price, selloff, image, infos[0],
        infos[1], infos[2], infos[3], infos[4]]
    end

    next_page = page.search(".pagination .next a")
    if next_page.any?
      page = @mechanize.get(page.search(".pagination .next a").attribute("href").text)
    else
      break
    end
  end
  export page_name, results
end

def export page_name, results
  dirname = File.dirname("aaa")
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

  CSV.open("#{dirname + page_name}.csv", "w+") do |csv_file|
    results.each do |row|
      csv_file << row
    end
  end
end

def main
  links.each do |link|
    crawler link
  end
end

main
