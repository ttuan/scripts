require "dotenv/load"
require "bundler"
Bundler.require

require "./vps_account"
require "./spreadsheet_updater"

vps_net_asset = VpsRequester.new.vps_net_asset
SpreadsheetUpdater.new(vps_net_asset).run


