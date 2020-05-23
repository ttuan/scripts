#!/usr/bin/ruby

require "pry"
require "concurrent-ruby"
require "date"
require "json"
require "net/http"

ARGS_SPERATOR = '='
DATE_FORMAT = "%Y-%m-%d"

class Args
  attr_reader :args

  def perform
    parse_args
    return {} unless valid_args?
    @args
  end

  private
  def parse_args
    @args = {}
    ARGV.each do |arg|
      data = arg.split(ARGS_SPERATOR)
      @args.merge! Hash[*data]
    end

    # For working with older ruby version
    @args = @args.inject({}) {|memo, (k, v)| memo[k.to_sym] = v; memo}
  end

  def valid_args?
    if ENV["GITHUB_TOKEN"].nil?
      puts "ENV['GITHUB_TOKEN'] is missing. You can get token here: https://github.com/settings/tokens/new?scopes=repo&description=Github_KPI_tool"
    end

    %i(repo from to).each do |arg|
      unless args.keys.include?(arg)
        puts "Missing '#{arg.to_s}' argument"
        return false
      end
    end

    begin
      @args[:from] = Date.strptime(args[:from], DATE_FORMAT)
      @args[:to] = Date.strptime(args[:to], DATE_FORMAT)
    rescue ArgumentError
      puts "Wrong date format, use '%Y-%m-%d' instead"
      return false
    end
  end
end

class GithubKpi
  attr_reader :args, :pull_requests

  def initialize args
    @args = args
    @comments, @additions, @deletions = 0, 0, 0
  end

  def perform
    if pull_requests.nil?
      puts "Can not fetch pull requests. Please recheck args"
      return
    end
    promises = []

    print "Calculating "
    pull_requests.each do |pull_request|
      promises.push(
        Concurrent::Promise.new do
          get_pr_detail pull_request[:number]
        end
      )
    end

    promises.each(&:execute)

    result = Concurrent::Promise.zip(*promises).value!
    result.each do |detail_pr|
      print "."
      @comments += detail_pr[:review_comments]
      @additions += detail_pr[:additions]
      @deletions += detail_pr[:deletions]
    end
    print "\n"

    reports = {number_prs: pull_requests.size, comments: @comments, additions: @additions, deletions: @deletions}
    puts reports
  end

  private
  def pull_requests
    @pull_requests ||= merged_pull_requests[:items]
  end

  def merged_pull_requests
    url = "https://api.github.com/search/issues?q=repo:#{args[:repo]} type:pr is:merged merged:#{args[:from]}..#{args[:to]}&per_page=200"
    github_request url
  end

  def get_pr_detail number
    url = "https://api.github.com/repos/#{args[:repo]}/pulls/#{number}"
    github_request url
  end

  def github_request url
    uri = URI.parse url
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true
    req = Net::HTTP::Get.new uri.request_uri
    req["Authorization"] = "Bearer #{ENV['GITHUB_TOKEN']}"
    JSON.parse http.request(req).body, symbolize_names: true
  end
end

args = Args.new.perform
GithubKpi.new(args).perform unless args.empty?
