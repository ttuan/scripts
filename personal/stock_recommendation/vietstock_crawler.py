import scrapy
import re
from datetime import datetime, timedelta


class StockSpider(scrapy.Spider):
    name = 'vietstock-spider'
    start_urls = ['https://finance.vietstock.vn/bao-cao-phan-tich']
    custom_user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    host = 'https://finance.vietstock.vn/'
    next_page_url = 'https://finance.vietstock.vn/View/ChannelEDocumentPage'
    cookie = ""
    csrf_token = ""
    time_range = 60 # days

    def start_requests(self):
        headers = {"User-Agent": self.custom_user_agent}
        for url in self.start_urls:
            yield scrapy.Request(url=url, headers=headers, callback=self.parse)

    def parse(self, response):
        STOCK_SELECTOR = '.edoc-child'
        TITLE_SELECTOR = '.title-link::text'
        URL_SELECTOR = '.title-link::attr(href)'
        DATE_SELECTOR = 'small.pull-right i::text'
        NEXT_SELECTOR = 'ul.pagination li.next a::attr(page)'
        SOURCE_SELECTOR = 'div.m-t.m-b-xs a.title-link::text'
        SOURCE_WITHOUT_LINK_SELECTOR = 'div.m-t.m-b-xs b.title::text'

        for stock in response.css(STOCK_SELECTOR):
            title = stock.css(TITLE_SELECTOR).get()
            stock_code = title.split(':')[0]
            if not stock_code or len(stock_code) != 3:
                continue

            date = stock.css(DATE_SELECTOR).get()
            date = datetime.strptime(date, '%d/%m/%Y')
            date = date.strftime('%Y-%m-%d')

            yield {
                'date': date,
                'code': stock_code,
                'source': stock.css(SOURCE_SELECTOR).get() or stock.css(SOURCE_WITHOUT_LINK_SELECTOR).get(),
                'title': stock.css(TITLE_SELECTOR).get(),
                'url': self.host + stock.css(URL_SELECTOR).get(),
            }

        next_page = response.css(NEXT_SELECTOR).get()
        if next_page:
            if not self.cookie:
                cookie = response.headers.getlist('Set-Cookie')
                for c in cookie:
                    if '__RequestVerificationToken' in c.decode("utf-8"):
                        self.cookie = c.decode("utf-8").split(';')[0]

            if not self.csrf_token:
                self.csrf_token = response.xpath('//*[@name="__RequestVerificationToken"]/@value').extract()[0]

            headers = {
                "User-Agent": self.custom_user_agent,
                "Cookie": self.cookie,
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            }

            form_data = {
                'keyword': '',
                'todate': datetime.today().strftime('%Y-%m-%d'),
                'fromdate': (datetime.today() - timedelta(days=self.time_range)).strftime('%Y-%m-%d'),
                'pageSize': '100',
                '__RequestVerificationToken': self.csrf_token,
                'sourceID': '0',
                'page': next_page
            }

            yield scrapy.FormRequest(url=self.next_page_url, formdata=form_data, headers=headers, callback=self.parse)
