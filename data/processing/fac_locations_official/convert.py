import pandas as pd

df = pd.read_json('test.json')

print(df.to_string()) 