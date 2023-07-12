import pandas as pd
import os

os.system('scrapy runspider vietstock_crawler.py -O vietstock.csv')
os.system('scrapy runspider tinnhanh_crawler.py -O tinnhanh.csv')

vietstock_df = pd.read_csv('vietstock.csv')
tinnhanh_df = pd.read_csv('tinnhanh.csv')

combined_df = pd.concat([vietstock_df, tinnhanh_df], ignore_index=True)
combined_df = combined_df.drop_duplicates(subset=['code', 'source', 'date'], keep='first')

def count_appearances(df):
    df['count'] = df.groupby(['code'])['code'].transform('count')
    return df
combined_df = count_appearances(combined_df)

combined_df.to_csv('combined.csv', index=False)

os.remove('vietstock.csv')
os.remove('tinnhanh.csv')
