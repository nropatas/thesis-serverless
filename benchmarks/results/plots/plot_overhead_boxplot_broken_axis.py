import os
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
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

# frameworks = ["AWS", "Azure"]
frameworks = ["Knative", "OpenFaaS", "Kubeless", "Fission"]
test_names = ["BurstLvl1", "BurstLvl2", "BurstLvl3", 
              "ConcurrentIncreasingLoadLvl1",  "ConcurrentIncreasingLoadLvl2", "ConcurrentIncreasingLoadLvl3", 
              "IncreasingCPULoadLvl1", "IncreasingCPULoadLvl2", "IncreasingCPULoadLvl3",
              "IncreasingMemLoadLvl1", "IncreasingMemLoadLvl2", "IncreasingMemLoadLvl3"]
ybreak_start = 2001
ybreak_end = 4000
yscale = 1000
yscale2 = 1000
ymin = 0
ymax = 6001

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

    successful_req_overheads = df.loc[df['failed'] == False]['invocationOverhead']
    print(framework, len(successful_req_overheads))
    plot_data.append(successful_req_overheads)

fig = plt.figure()
plt.rc('text', usetex=True)
plt.rc('font', family='sans-serif')
plt.rcParams['font.size'] = 20

s, (ax1, ax2)  = plt.subplots(2, 1, sharex=True)

ax1.boxplot(plot_data, widths=0.5, patch_artist=True)
bpl = ax2.boxplot(plot_data, widths=0.5, patch_artist=True)
ax1.set_ylim(ymin=ybreak_end)
ax2.set_ylim(ymax=ybreak_start)
ax1.spines['bottom'].set_visible(False)
ax2.spines['top'].set_visible(False)
ax1.tick_params(axis='x', bottom=False, top=False)
ax2.xaxis.tick_bottom()

for median in bpl['medians']:
    median.set(color='black', linewidth=1.5)

for patch in bpl['boxes']:
    patch.set_facecolor(LBLUE)

ax1.yaxis.grid(True)
ax2.yaxis.grid(True)

y_ticks = np.arange(ybreak_end, ymax, yscale)
ax1.set_yticks(y_ticks)
ax1.set_yticklabels(y_ticks)
y_ticks = np.arange(ymin, ybreak_start, yscale2)
ax2.set_yticks(y_ticks)
ax2.set_yticklabels(y_ticks)

ax2.set_xticklabels(frameworks)
ax2.set_xlabel('Platforms')
plt.gcf().text(0, 0.25, 'Invocation Overhead (ms)', rotation='vertical')

d = .015  # how big to make the diagonal lines in axes coordinates
# arguments to pass to plot, just so we don't keep repeating them
kwargs = dict(transform=ax1.transAxes, color='k', clip_on=False)
ax1.plot((-d, +d), (-d, +d), **kwargs)        # top-left diagonal
ax1.plot((1 - d, 1 + d), (-d, +d), **kwargs)  # top-right diagonal

kwargs.update(transform=ax2.transAxes)  # switch to the bottom axes
ax2.plot((-d, +d), (1 - d, 1 + d), **kwargs)  # bottom-left diagonal
ax2.plot((1 - d, 1 + d), (1 - d, 1 + d), **kwargs)  # bottom-right diagonal

plt.tight_layout()

# pdf = PdfPages('final-overhead-boxplot-cpulvl1-opensrc.pdf')
# pdf.savefig(fig)
# pdf.close()

plt.show()
