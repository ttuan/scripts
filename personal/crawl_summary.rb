require 'wombat'

BASE_URL = 'https://ttuan.xyz'
SITES = %w(/posts /til)
@summary = []

def get_links
  SITES.each do |site|
    links = Wombat.crawl do
      base_url BASE_URL
      path site

      list "css=.list-item-header", :iterator do
        title 'css=a'
        url({xpath: ".//a[1]/@href"})
      end
    end
    @summary += links["list"]
  end
end

def export_md
  File.open("/Users/natu/Dropbox/Projects/side_projects/knowledge/sharing/my_blog.md", "w") do |f|
    content = <<~HEREDOC
    # Blog Aricles

    ## Links
    HEREDOC

    @summary.each do |article|
      content += "* [#{article['title']}](#{BASE_URL + article['url']})\n"
    end

    f.write content
  end
end

def main
  get_links
  export_md
end

main
