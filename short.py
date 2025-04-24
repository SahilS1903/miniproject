
import pandas as pd
df=pd.read_csv('iot_test_data.csv')
df=df.sample(10)
df.to_csv('iot_test_data_short.csv',index=False)
