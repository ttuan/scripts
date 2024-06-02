require 'notion-sdk-ruby'
require 'pony'

class NotionHighlight
  NOTION_DATABASE_NAME = "Kindle Highlights & Notes"
  HIGHLIGHTS_COUNT = 5
  NOTION_API_TOKEN="your-notion-token"

  def run
    book_blocks = client.blocks.children.list(book["id"]).data
    choosen_highlights = highlights(book_blocks).sample(HIGHLIGHTS_COUNT)

    {
      title: book_title,
      url: book_url,
      highlights: choosen_highlights
    }
  end

  private
  def client
    @client ||= Notion::Client.new(token: NOTION_API_TOKEN)
  end

  def highlights all_book_blocks
    if all_book_blocks.size == 1
      # New format
      all_book_blocks.first.paragraph["rich_text"].map { |block| block["text"]["content"] }.join.split("\n\n")
    else
      # Old format
      all_highlights = all_book_blocks.map { |b| b.paragraph["rich_text"].map { |block| block["text"]["content"] }.join("\n") }

      if all_highlights.any? { |note| note.start_with?("A highlight is created") }
        all_highlights = all_highlights.each_slice(2).map { |slice| slice.join("\n") }
      end

      all_highlights
    end
  end

  def kindle_highlight_page
    results = client.search(query: NOTION_DATABASE_NAME, filter: { property: 'object', value: 'database' })
    results.data.find { |db| db['title'].any? && db['title'][0]['text']['content'] == NOTION_DATABASE_NAME }
  end

  def books
    @books ||= client.databases.query(kindle_highlight_page["id"], {}).data
  end

  def book
    return @book unless @book.nil?

    loop do
      @book = books.sample
      next if is_review?(@book)

      return @book
    end
  end

  def is_review?(book)
    book["properties"]["Tags"]["multi_select"].any?{|tag| tag["name"] == "review" }
  end

  def book_title
    @book["properties"]["Title"]["title"].first["plain_text"]
  end

  def book_url
    @book["url"]
  end
end


class Notion2Email
  GMAIL_USERNAME = "gmail-username"
  GMAIL_PASSWORD = "gmail-password"
  SEND_TO = "your-email"

  def run
    send_mail content
  end

  private
  def content
    notion_highlights = NotionHighlight.new.run

    # <img style="display: block; margin-left: auto; margin-right: auto; width: 50%;" src="https://ph-files.imgix.net/d0dcaa9c-a5e9-49c4-94a3-ee277aad23be.jpeg?auto=format" alt="">
    content = <<~CONTENT
    <h1 style="text-align: center">Daily Higlights</h1>

    <div>
      Highlights from book: <strong>#{notion_highlights[:title]}</strong>
    </div>
    <hr style="border-top: 3px solid #bbb"/></br>
    CONTENT

    notion_highlights[:highlights].each do |highlight|
      highlight.gsub!("\n", "<br/>")
      content += <<~HIGHLIGHT
      <div>
        #{highlight}
      </div>
      <br/> <hr/><br/>
      HIGHLIGHT
    end

    content += "Read more on <a href=#{notion_highlights[:url]}>Notion book page</a>"

    content
  end

  def send_mail content
    Pony.mail({
      :to => SEND_TO,
      :via => :smtp,
      :subject => "Daily Highlights From Kindle",
      :html_body => content,
      :via_options => {
        :address              => 'smtp.gmail.com',
        :port                 => '587',
        :enable_starttls_auto => true,
        :user_name            => GMAIL_USERNAME,
        :password             => GMAIL_PASSWORD,
        :authentication       => :plain # :plain, :login, :cram_md5, no auth by default
      }
    })
  end
end

Notion2Email.new.run
