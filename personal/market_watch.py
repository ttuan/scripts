import requests
from bs4 import BeautifulSoup
from datetime import date, datetime
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

ICONS = {
    "VN1Y": "📉",  # Bond Yield Down
    "VN10Y": "📈",  # Bond Yield Up
    "USDVND": "💵",  # Currency
    "DXY": "💰",  # Dollar Index
    "Gold Price": "🥇",  # Gold
    "VN Gold Prices": "🏅",  # Vietnam Gold
    "Brent Oil": "⛽",  # Oil
    "US10Y": "📊",  # US Bond Yield
    "ON": "📰"  # Market Watch
}

# Headers for all requests
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
}

def fetch_soup(url, verify=True):
    """Fetches and parses the HTML content of a given URL."""
    try:
        response = requests.get(url, headers=HEADERS, verify=verify)
        response.raise_for_status()
        return BeautifulSoup(response.content, 'html.parser')
    except requests.exceptions.RequestException as e:
        print(f"Error fetching {url}: {e}")
        return None


def get_on_interest():
    base_url = "https://vira.org.vn"

    """Fetches the 'MONEY MARKET' image URL from VIRA's daily news."""
    soup = fetch_soup(f"{base_url}/tin/Ban-tin.html")
    if not soup:
        return None

    today_date = date.today().strftime("%d/%m/%Y")

    # Primary Search: Find link with today's date
    link = None
    for header in soup.find_all('header', class_='story__header'):
        meta_time = header.find('div', class_='story__meta').find('time')
        if meta_time and today_date in meta_time.text:
            link = header.find('a')['href']
            break

    # Fallback Search: Find first occurrence of "Market Watch" in title
    if not link:
        print("Market Watch link not found. Searching by title...")

        # Locate the first "row" container
        row_div = soup.find('div', class_='row')
        if not row_div:
            print("No content found inside 'row'.")
            return None

        articles = row_div.find_all('article', class_='story')
        if not articles:
            print("No 'article.story' elements found inside 'row'.")
            return None

        for article in articles:
            title_tag = article.find('h3', class_='story__title')
            if title_tag and "Market Watch" in title_tag.text:
                link = title_tag.find('a')['href']
                break

    if not link:
        print("Market Watch article not found.")
        return None

    # Fetch the article page
    new_soup = fetch_soup(f"{base_url}{link}")
    if not new_soup:
        return None

    # Find 'MONEY MARKET' section and get the first image
    money_market_section = new_soup.find(string="MONEY MARKET")
    if money_market_section:
        image = money_market_section.find_next('img')
        return image['src'] if image and 'src' in image.attrs else "Image not found."

    return "MONEY MARKET section not found."

def fetch_trading_data(url, symbol, label):
    """Fetches financial data from Trading Economics given a symbol."""
    soup = fetch_soup(url)
    if not soup:
        return None

    row = soup.find('tr', {'data-symbol': symbol})
    if row:
        price = row.find('td', id='p').text.strip()
        day_change = row.find('td', id='pch').text.strip()
        date_value = row.find('td', id='date').text.strip()
        return f"`{price}`, Day Change: `{day_change}` ({date_value})"

    print(f"{label} details not found.")
    return None

def get_vn10y_bond_details():
    return fetch_trading_data("https://tradingeconomics.com/vietnam/government-bond-yield",
                              "VNMGOVBON10Y:GOV", "VN10Y")

def get_dxy_index():
    return fetch_trading_data("https://tradingeconomics.com/united-states/currency",
                              "DXY:CUR", "DXY")

def get_usdvnd_value():
    return fetch_trading_data("https://tradingeconomics.com/usdvnd:cur",
                              "USDVND:CUR", "USD/VND")

def get_brent_crude_oil_value():
    return fetch_trading_data("https://tradingeconomics.com/commodity/brent-crude-oil",
                              "CO1:COM", "Brent Oil")

def get_us10y_bond_yield():
    return fetch_trading_data("https://tradingeconomics.com/united-states/government-bond-yield",
                              "USGG10YR:IND", "US10Y")

def get_gold_price():
    return fetch_trading_data("https://tradingeconomics.com/commodity/gold",
                              "XAUUSD:CUR", "Gold Price")

def get_vietnam_1y_bond_yield():
    """Fetches Vietnam 1Y bond yield from Investing.com."""
    url = "https://vn.investing.com/rates-bonds/vietnam-1-year-bond-yield-streaming-chart"
    soup = fetch_soup(url)
    if not soup:
        return None

    try:
        yield_value = soup.find('div', {'data-test': 'instrument-price-last'}).text.strip()
        change_percent = soup.find('span', {'data-test': 'instrument-price-change-percent'}).text.strip()
        return f"`{yield_value}`, Change: {change_percent}"
    except AttributeError:
        print("VN1Y Bond Yield details not found.")
        return None

def get_vn_gold_prices():
    """Fetches Vietnam gold prices from Doji.vn."""
    url = "https://doji.vn/bang-gia-vang/"
    soup = fetch_soup(url, verify=False)
    if not soup:
        return None, None

    taxonomy_blocks = soup.find('div', class_='_taxonomy').find_all('div', class_='_block')
    sell_blocks = soup.find('div', class_='_Sell').find_all('div', class_='_block')

    prices = []
    for index, block in enumerate(taxonomy_blocks):
        if "SJC HN - Bán Lẻ" in block.text:
            prices.append(f"SJC HN - Bán Lẻ: `{sell_blocks[index].text.strip()}`")
        elif "Nhẫn Tròn 9999" in block.text:
            prices.append(f"Nhẫn Tròn 9999: `{sell_blocks[index].text.strip()}`")

    return ", ".join(prices) if prices else "No prices found."

def send_prices_to_slack(token, channel):
    """Fetches financial prices and sends a formatted list message to Slack."""
    client = WebClient(token=token)

    prices = {
        "US10Y": get_us10y_bond_yield(),
        "VN10Y": get_vn10y_bond_details(),
        "Brent Oil": get_brent_crude_oil_value(),
        "Gold Price": get_gold_price(),
        "VN Gold Prices": get_vn_gold_prices(),
        "DXY": get_dxy_index(),
        "VN1Y": get_vietnam_1y_bond_yield(),
        "USDVND": get_usdvnd_value(),
        "ON": get_on_interest()
    }

    today_date = datetime.now().strftime("%Y-%m-%d")

    # Format message in Slack Block Kit
    blocks = [{"type": "section", "text": {"type": "mrkdwn", "text": f"*Market Update - {today_date}*"}}]

    for label, value in prices.items():
        if value:
            icon = ICONS.get(label, "📌")
            text = f"{icon} *{label}*: {value}"
            blocks.append({"type": "section", "text": {"type": "mrkdwn", "text": text}})

    try:
        client.chat_postMessage(channel=channel, blocks=blocks)
        print("Send Slack message success.")
    except SlackApiError as e:
        print(f"Error sending message: {e.response['error']}")

send_prices_to_slack("your-slack-token", "your-slack-channel")
