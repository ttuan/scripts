require 'mechanize'

agent = Mechanize.new

def search_data(table, row_text, column)
  row = table.search('tr').find do |r|
    r.text.include?(row_text)
  end

  row.search('td')[column].text.strip
end

# LSLNH
page = agent.get('https://www.sbv.gov.vn/webcenter/portal/vi/menu/rm/ls/lsttlnh')
table = page.search('table.jrPage tbody')

apply_date = search_data(table, 'Ngày áp dụng', 0)
lslnh_on = search_data(table, 'Qua đêm', 1)
puts '==============================='
puts "LSLNH - ON: #{lslnh_on}. #{apply_date}"

# OMO
page = agent.get('https://www.sbv.gov.vn/webcenter/portal/vi/menu/trangchu/hdtttt/ttm')
table = page.search('table.jrPage tbody')

apply_date = page.search('table.jrPage tbody tr:nth-child(6) td:nth-child(1)').first.text.strip
omo = search_data(table, 'Tổng cộng', 2)
puts '==============================='
puts "Bơm OMO: #{omo}. #{apply_date}"

# Tín phiếu
page = agent.get('https://www.sbv.gov.vn/webcenter/portal/vi/menu/trangchu/hdtttt/ttcbtpnhnn')
table = page.search('table.jrPage tbody')
apply_date = search_data(table, 'Ngày đấu thầu', 1)
puts '==============================='
puts "Tín phiếu: Ngày áp dụng: #{apply_date}"
