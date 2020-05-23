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
parser.add_argument('--single-iteration', '-s', dest='selected_iter', help='Specify an iteration for which plot is generated', required=False, type=int)
args = parser.parse_args()

frameworks = ["aws", "azure"]
# frameworks = ["knative", "openfaas", "kubeless", "fission"]
test_names = ["BurstLvl1", "BurstLvl2", "BurstLvl3", 
              "ConcurrentIncreasingLoadLvl1",  "ConcurrentIncreasingLoadLvl2", "ConcurrentIncreasingLoadLvl3", 
              "IncreasingCPULoadLvl1", "IncreasingCPULoadLvl2", "IncreasingCPULoadLvl3",
              "IncreasingMemLoadLvl1", "IncreasingMemLoadLvl2", "IncreasingMemLoadLvl3"]

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

# Show only successful responses
print('\nfiltered data:')
cold_start = []
warm_start = []
for framework in frameworks:
    if args.selected_iter and args.selected_iter > 0 and args.selected_iter <= args.iterations:
        df = total_data[framework]['iterations'][args.selected_iter - 1]
    else:
        df = total_data[framework]['all']

    cold_overheads = df.loc[(df['failed'] == False) & (df['reused'] == False)]['invocationOverhead']
    warm_overheads = df.loc[(df['failed'] == False) & (df['reused'] == True)]['invocationOverhead']
    print(framework, 'cold', len(cold_overheads))
    print(framework, 'warm', len(warm_overheads))
    cold_start.append(np.mean(cold_overheads))
    warm_start.append(np.mean(warm_overheads))

plt.figure()
plt.rc('text', usetex=True)
plt.rc('font', family='sans-serif')

x = np.arange(len(frameworks))
width = 0.25

s = plt.subplot(1,1,1)
s.bar(x - width / 2, cold_start, width, label='Cold Start')
s.bar(x + width / 2, warm_start, width, label='Warm Start')

s.set_xticklabels(frameworks)
s.set_xticks(x)
plt.ylabel('Average Invocation Overhead (ms)')
plt.legend()

plt.tight_layout()
plt.show()
