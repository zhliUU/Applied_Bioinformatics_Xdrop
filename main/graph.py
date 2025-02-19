#!/opt/conda/bin/python

import sys
#import matplotlib.pyplot as plt # remove plot function
import numpy as np
from tabulate import tabulate
print ('If return an error, make sure the python libraries installed to the python version list below!')
print(sys.version)

# COMMAND: python graph.py 'InputPositions' 'resultT2' 'fileOutputName' 'PrefixForBarChart'
# INPUT: Pathway to text based files.
# OUTPUT: Table and bar chart

def WriteToFile(line):
	f=open(sys.argv[3], "a+")
	f.write(line)
	f.close()
	return None

def main():
	f = open(sys.argv[1])
	if str(sys.argv[4]) == '!@?':
		barChart ='bar_chart.png'
	else:
		barChart = sys.argv[4] + 'bar_chart.png'
	countArr = []
	absPos = []
	absPosStr = ''
	freq = []
	ID = []
	comboArr = []
	comboArrStr = []
	check = 0
	numPos = 0
	sumCount = 0
	line = f.readline()
	if "\t" not in line:
		tmpRead = line.split(' ')
	else:
		tmpRead = line.split('\t')
	while line:
		absPos.append(tmpRead[0])
		if check != 1:
			absPosStr = absPosStr + tmpRead[0]
			check = 1
		else:
			absPosStr = absPosStr + ',' + tmpRead[0]
		line = f.readline()
		if "\t" not in line:
			tmpRead = line.split(' ')
		else:
			tmpRead = line.split('\t')

	f.close()

	f = open(sys.argv[2])
	line = f.readline()
	if "\t" not in line:
		tmpRead = line.split(' ')
	else:
		tmpRead = line.split('\t')
	while line:
		countArr.append(tmpRead[0])
		freq.append(float(tmpRead[0]))
		tmpRead = tmpRead[1:]
		#tmpRead.pop(0)
		if check != 0:
			numPos = len(tmpRead)
			check = 0
		tmpStr = ''
		for x in tmpRead:
			x = x.replace('\n','')
			comboArr.append(x)
			if tmpStr == '':
				tmpStr = tmpStr + x
			else:
				tmpStr = tmpStr + '\t' + '\t' + x
		comboArrStr.append(tmpStr)
		line = f.readline()
		if "\t" not in line:
			tmpRead = line.split(' ')
		else:
			tmpRead = line.split('\t')

	f.close()

	for i in range(len(countArr)):
		ID.append(i+1)
		sumCount = sumCount + freq[i]

	for i in range(len(freq)):
		freq[i] = freq[i] / float(sumCount)

	header = ['ID', 'Count', 'Frequency', absPosStr]
	t = []
	for i in range(len(comboArrStr)):
		column = [ID[i], countArr[i],freq[i],comboArrStr[i]]
		t.append(column)

	final_table = tabulate(t,header)
	print (tabulate(t,header))
	WriteToFile(final_table)

	#######making bar chart
	#ID.insert(0,0)
	#ind = np.arange(len(ID))
	#width = 0.15
	#plt.bar(ID[1:], freq)
	#plt.xticks(ind, ID)
	#plt.yticks(np.arange(0, 1.1,0.1))
	#plt.ylabel('Percentage')
	#plt.xlabel('ID')
	#plt.title('Frequency of different combinations')
	#plt.savefig(barChart)   # save the figure to file
	#plt.close(fig)
	#plt.show()

	#t = PrettyTable(['ID', 'Count', 'Frequency', absPosStr])
	#for i in range(len(comboArrStr)):
	#	t.add_row([ID[i], countArr[i],freq[i],comboArrStr[i]])
	#print (t)

	#print(countArr)
	#print(absPos)
	#print(absPosStr)
	#print(freq)
	#print(ID)
	#print(comboArr)
	#print(comboArrStr)
	#print(check)
	#print(numPos)
	#print(sumCount)
	return
main()
