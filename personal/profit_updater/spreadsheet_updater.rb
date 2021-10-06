require "dotenv/load"
require "bundler"
Bundler.require

class SpreadsheetUpdater
  def initialize data = {}
    @data = data
  end

  def run
    updated_data.each.with_index(1) do |value, index|
      sheet[today_row_index, index] = value
    end

    sheet.save
  end

  private
  attr_accessor :sheet, :data

  def updated_data
    [
      today,
      (data[:vndirect] || sheet[yesterday_row_index, 2].split(',')[0].gsub('.', '')),
      (data[:vps_normal] || sheet[yesterday_row_index, 3].split(',')[0].gsub('.', '')),
      (data[:vps_margin] || sheet[yesterday_row_index, 4].split(',')[0].gsub('.', '')),
      "=SUM(B#{today_row_index}:D#{today_row_index})",
      "=E#{today_row_index} - E#{yesterday_row_index} - (H#{today_row_index} - H#{yesterday_row_index})",
      "=(E#{today_row_index} - H#{yesterday_row_index})",
      "=H#{yesterday_row_index}",
      "=G#{today_row_index} / H#{today_row_index}"
    ]
  end

  def sheet
    return @sheet unless @sheet.nil?

    session = GoogleDrive::Session.from_service_account_key(ENV["CLIENT_SECRET_FILE_PATH"])
    spreadsheet = session.spreadsheet_by_key(ENV["SPREADSHEET_ID"])
    @sheet = spreadsheet.worksheet_by_title(ENV["WORKSHEET_TITLE"])
  end

  def today
    @today ||= Time.now.strftime("%d/%m/%Y")
  end

  def today_row_index
    @today_row_index ||= sheet.rows.find_index {|row| row[0] == today} + 1
  end

  def yesterday_row_index
    @yesterday_row_index ||= today_row_index - 1
  end
end
