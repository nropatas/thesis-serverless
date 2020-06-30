import os
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter


# Colors
WHITE = '#FFFFFF'
GRAY = '#707070'
LORANGE = '#FF9900'
LGREEN = '#66FF33'
LYELLOW = '#FFFF66'
LBLUE = '#6699FF'
LRED = '#FF3333'
PALEGREEN = '#14E89C'

parser = argparse.ArgumentParser(description='Plot bar chart')
parser.add_argument('--directory', '-d', dest='directory', help='Directory path where CSV files are located', required=True, type=str)
parser.add_argument('--test', '-t', dest='test_name', help='Test name for which plot is generated', required=True, type=str)
parser.add_argument('--iterations', '-i', dest='iterations', help='Number of iterations for which plot is to be generated', required=True, type=int)
args = parser.parse_args()

# frameworks = ["aws", "azure"]
# frameworks = ["knative", "openfaas", "kubeless", "fission"]
# frameworks = ["kubeless", "fission"]
frameworks = ["aws", "azure", "knative", "openfaas", "kubeless", "fission"]
test_names = ["BurstLvl1", "BurstLvl2", "BurstLvl3", 
              "ConcurrentIncreasingLoadLvl1",  "ConcurrentIncreasingLoadLvl2", "ConcurrentIncreasingLoadLvl3", 
              "IncreasingCPULoadLvl1", "IncreasingCPULoadLvl2", "IncreasingCPULoadLvl3",
              "IncreasingMemLoadLvl1", "IncreasingMemLoadLvl2", "IncreasingMemLoadLvl3"]
# For getting success rates of the particular memory allocation
# memory = 2048

print('total data:')
total_data = {}
# Read data from csv files
for framework in frameworks:
    filenames = [args.directory + "/" + args.test_name + "_" + framework + "_" + str(i) + ".csv" for i in range(1,args.iterations+1)]
    framework_data = []
    for file in filenames:
        if not os.path.isfile(file):
            print("File {} does not exist".format(file))
            exit(1)
        framework_data.append(pd.read_csv(file))

    total_data[framework] = {}
    total_data[framework]['all'] = pd.concat(framework_data)
    total_data[framework]['iterations'] = framework_data

    # TODO: Check that all files have consistent number of lines/data 
    print(framework, len(total_data[framework]['all']))

print('\nfiltered data:')
plot_data = []
for framework in frameworks:
    df = total_data[framework]['all']
    if 'memory' in globals():
        num_total = df.loc[df['memory'] == memory].shape[0]
        num_success = df.loc[(df['failed'] == False) & (df['memory'] == memory)].shape[0]
    else:
        num_total = df.shape[0]
        num_success = df.loc[df['failed'] == False].shape[0]
    print(framework, num_success, 'out of', num_total)
    plot_data.append(0 if num_total == 0 else (num_success / num_total) * 100)

# Data for a table
print('')
for i, framework in enumerate(frameworks):
    s = framework
    percents = []
    for df in total_data[framework]['iterations']:
        if 'memory' in globals():
            num_total = df.loc[df['memory'] == memory].shape[0]
            num_success = df.loc[(df['failed'] == False) & (df['memory'] == memory)].shape[0]
        else:
            num_total = df.shape[0]
            num_success = df.loc[df['failed'] == False].shape[0]
        percent = 0 if num_total == 0 else (num_success / num_total) * 100
        percents.append(percent)
        s += ' & {:.1f}'.format(percent)
    s += ' & {:.1f}, s.d. = {:.1f}'.format(plot_data[i], np.std(percents))
    print(s)

plt.figure()
plt.rc('text', usetex=True)
plt.rc('font', family='sans-serif')

x = np.arange(len(frameworks))
width = 0.25

s = plt.subplot(1,1,1)
s.bar(x, [100] * len(plot_data), width, color='lightgray')
s.bar(x, plot_data, width)

s.set_xticklabels(frameworks)
s.set_xticks(x)
plt.ylabel('Success Rate (\%)')

plt.tight_layout()
plt.show()
