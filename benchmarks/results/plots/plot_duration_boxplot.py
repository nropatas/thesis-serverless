import os
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
from matplotlib.backends.backend_pdf import PdfPages


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

frameworks = ["AWS", "Azure"]
# frameworks = ["Knative", "OpenFaaS", "Kubeless", "Fission"]
test_names = ["BurstLvl1", "BurstLvl2", "BurstLvl3", 
              "ConcurrentIncreasingLoadLvl1",  "ConcurrentIncreasingLoadLvl2", "ConcurrentIncreasingLoadLvl3", 
              "IncreasingCPULoadLvl1", "IncreasingCPULoadLvl2", "IncreasingCPULoadLvl3",
              "IncreasingMemLoadLvl1", "IncreasingMemLoadLvl2", "IncreasingMemLoadLvl3"]
memory = 0

print('total data:')
total_data = {}
# Read data from csv files
for framework in frameworks:
    framework = framework.lower()
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
plot_data = []
for framework in frameworks:
    framework = framework.lower()
    if args.selected_iter and args.selected_iter > 0 and args.selected_iter <= args.iterations:
        df = total_data[framework]['iterations'][args.selected_iter - 1]
    else:
        df = total_data[framework]['all']

    if framework == 'aws':
        num = 0
        for mem in [128, 256, 512, 1024, 2048]:
            successful_req_durations = df.loc[(df['failed'] == False) & (df['memory'] == mem)]['duration']
            plot_data.append(successful_req_durations)
            num += len(successful_req_durations)
        print(framework, num)
    else:
        successful_req_durations = df.loc[(df['failed'] == False) & ((df['memory'] == memory) | (df['memory'] == 0))]['duration']
        print(framework, len(successful_req_durations))
        plot_data.append(successful_req_durations)

fig = plt.figure()
plt.rc('text', usetex=True)
plt.rc('font', family='sans-serif')

s = plt.subplot(1,1,1)

bpl = plt.boxplot(plot_data, widths=0.5, patch_artist=True)
plt.setp(bpl['boxes'], color='black')
plt.setp(bpl['whiskers'], color='black')
plt.setp(bpl['fliers'], color='black')

for median in bpl['medians']:
    median.set(color='black', linewidth=1.5)

for patch in bpl['boxes']:
    patch.set_facecolor(LORANGE)

s.yaxis.grid(True)
s.xaxis.get_label().set_fontsize(20)
s.yaxis.get_label().set_fontsize(20)

temp_ticks = []
for i in s.get_yticks():
    temp_ticks.append(int(i))
s.set_yticklabels(temp_ticks)

for tick in s.xaxis.get_major_ticks():
    tick.label1.set_fontsize(20)
for tick in s.yaxis.get_major_ticks():
    tick.label1.set_fontsize(20)

if 'AWS' in frameworks:
    s.set_xticklabels(['AWS\n128MB', 'AWS\n256MB', 'AWS\n512MB', 'AWS\n1024MB', 'AWS\n2048MB', 'Azure'])
else:
    s.set_xticklabels(frameworks)
plt.xlabel('Platforms')
plt.ylabel('Function Duration (ms)')

plt.tight_layout()

# pdf = PdfPages('final-duration-boxplot-cpulvl1-public.pdf')
# pdf.savefig(fig)
# pdf.close()

plt.show()
