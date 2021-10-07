require "dotenv/load"
require "bundler"
Bundler.require

require "./vps_requester"
require "./vnd_requester"
require "./spreadsheet_updater"

vps_net_asset = VpsRequester.new.vps_net_asset
vnd_net_asset = VndRequester.new.vnd_net_asset
data = vps_net_asset.merge(vnd_net_asset)

SpreadsheetUpdater.new(data).run
