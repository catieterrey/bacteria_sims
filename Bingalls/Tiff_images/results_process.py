import numpy as np
import pandas as pd 

#read in csv file
frame1 = pd.read_csv('C:\\Users\\catie\\Documents\\code\\Bingalls\\Tiff_images\\results_frame1.csv')

#gives general info about csv file
frame1.info()

#seperates mesh column from the rest of the csv file
mesh1 = frame1['mesh']

#split the column into 4 columns which are x1,y1,x2,y2
mesh2 = mesh1.str.split(';',expand=True)

#name the columns
mesh3 = mesh2.rename(columns={0:'x1',1:'y1',2:'x2',3:'y2'})

#drop x2 column
mesh4 = mesh3.drop('x2',axis=1,inplace=False)

#drop y2 column
mesh5 = mesh4.drop('y2',axis=1,inplace=False)

#extract x1 values and y1 values to x1values and y1values, respectively
x1values = mesh5['x1']
y1values = mesh5['y1']

#split the column into individual coordinate columns (97 of them)
x1values2 = x1values.str.split(' ',expand=True)
y1values2 = y1values.str.split(' ',expand=True)

#replace empty columns with NAN
x1values2=x1values2.replace('',np.nan,inplace=False)
x1values3 = x1values2.fillna(value=np.nan,inplace=False)

y1values2=y1values2.replace('',np.nan,inplace=False)
y1values3 = y1values2.fillna(value=np.nan,inplace=False)

#takes final position of each bacteria cell and stores in an array
x1final = np.empty((75,1))
for i in range(75):
    x1final[i] = x1values3.loc[i].at[x1values3.loc[i].last_valid_index()]

y1final = np.empty((75,1))
for i in range(75):
    y1final[i] = y1values3.loc[i].at[y1values3.loc[i].last_valid_index()]

#takes initial position of each bacteria cell and stores in an array
x1initial=np.empty((75,1))
for i in range(75):
    x1initial[i]=x1values3.loc[i].at[0]
    
y1initial=np.empty((75,1))
for i in range(75):
    y1initial[i]=y1values3.loc[i].at[0]

#turn each array into a dataframe
x1i = pd.DataFrame(data=x1initial)
y1i = pd.DataFrame(data=y1initial)
x1f = pd.DataFrame(data=x1final)
y1f = pd.DataFrame(data=y1final)

#merge the dataframes as columns
data = pd.concat([x1i,y1i,x1f,y1f],axis=1).transpose()

#export dataframe to csv file
data.to_csv('C:\\Users\\catie\\Documents\\code\\Bingalls\\Tiff_images\\initialpositions2.csv')


