from telethon.sync import TelegramClient
from datetime import datetime, timezone
import re

# Note that your file need a metadata line which contain 'lastmod: ...'
api_id = 'your_api_id'
api_hash = 'your_api_hash'
saved_messages_file = 'your_local_file_path'


def get_lastmod(filename):
    with open(filename, 'r') as f:
        for line in f:
            if 'lastmod:' in line:
                match = re.search(r'lastmod: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{4})', line)
                if match:
                    lastmod = match.group(1)
                    return lastmod


def fetch_telegram_messages(lastmod):
    messages = []

    with TelegramClient('syncMessage', api_id, api_hash) as client:
        for message in client.iter_messages('me', reverse=True, offset_date=lastmod):
            if message.text:
                messages.append(message.text)

    return messages


def append_messages(filename, messages):
    with open(filename, 'a') as f:
        for line in messages:
            f.write(line + '\n' * 2 + '---' + '\n')


def update_lastmod(filename):
    with open(filename, 'r') as f:
        file_contents = f.read()

    current_time = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S%z')
    pattern = r"lastmod: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}\d{2})"
    replacement = f"lastmod: {current_time}"
    new_contents = re.sub(pattern, replacement, file_contents)

    with open(filename, 'w') as f:
        f.write(new_contents)


def main():
    lastmod = get_lastmod(saved_messages_file)
    date = datetime.strptime(lastmod, '%Y-%m-%dT%H:%M:%S%z')
    messages = fetch_telegram_messages(date)
    append_messages(saved_messages_file, messages)
    update_lastmod(saved_messages_file)


if __name__ == "__main__":
    main()
