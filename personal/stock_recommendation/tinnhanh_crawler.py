import scrapy
import re
import json
import datetime


class StockSpider(scrapy.Spider):
    name = 'tinnhanh-spider'
    start_urls = ['https://www.tinnhanhchungkhoan.vn/baocaophantich.html']
    host = 'https://www.tinnhanhchungkhoan.vn'
    current_page = 1

    time_range = 60 # days

    def parse(self, response):
        STOCK_SELECTOR = '.content-list article.story'
        TITLE_SELECTOR = '.story__heading a::text'
        URL_SELECTOR = '.story__heading a::attr(href)'
        DATE_SELECTOR = '.story__meta time::attr(datetime)'

        for stock in response.css(STOCK_SELECTOR):
            title = stock.css(TITLE_SELECTOR).get()

            source = re.search(r'([A-Z]+):', title)
            if source:
                source = source.group(1)

            stock_code = re.search(r':.*?([A-Z]([A-Z\d]{2}))', title)
            if stock_code:
                stock_code = stock_code.group(1)

            if not source or not stock_code:
                continue

            date = stock.css(DATE_SELECTOR).get()
            date = date.split('T')[0]

            yield {
                'date': date,
                'code': stock_code,
                'source': source,
                'title': title,
                'url': self.host + stock.css(URL_SELECTOR).get(),
            }

        self.current_page += 1
        next_page_url = f"https://api.tinnhanhchungkhoan.vn/api/morenews-report-0-{self.current_page}.html?phrase=&source_id=0&branch_id=0"
        yield scrapy.Request(url=next_page_url, callback=self.parse_json)

    def parse_json(self, response):
        finished = False

        response_data = json.loads(response.body)
        reports = response_data['data']['reports']

        for stock in reports:
            title = stock['title']

            source = re.search(r'([A-Z]+):', title)
            if source:
                source = source.group(1)

            stock_code = re.search(r':.*?([A-Z]([A-Z\d]{2}))', title)
            if stock_code:
                stock_code = stock_code.group(1)

            if not source or not stock_code:
                continue

            unix_date = stock['date']
            date = datetime.datetime.fromtimestamp(unix_date)
            date_data = date.strftime('%Y-%m-%d')

            if (datetime.datetime.now() - date).days > self.time_range:
                finished = True
                break

            yield {
                'date': date_data,
                'code': stock_code,
                'source': source,
                'title': title,
                'url': self.host + stock['url'],
            }

        load_more = response_data['data']['load_more']
        if load_more and not finished:
            self.current_page += 1
            next_page_url = f"https://api.tinnhanhchungkhoan.vn/api/morenews-report-0-{self.current_page}.html?phrase=&source_id=0&branch_id=0"
            yield scrapy.Request(url=next_page_url, callback=self.parse_json)
