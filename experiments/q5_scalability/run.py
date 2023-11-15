import os
import sys

script_dir = os.path.dirname(__file__)
modules_dir = os.path.join(script_dir, '..')
sys.path.append(modules_dir)

from tqdm import tqdm

from math import log
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def generate_scalability_plots(methods,
                               path,
                               datasets,
                               dimensions = 2,
                               n_clusters = 2,
                               ):
    means = []

    groups = [
        ['k'], # EMOutlier
        ['k'], # KMeansOutlierDetection
        ['k','l'], # KMeansMinusMinusOutlierDetection
        ['k','l'], # KMeansMinusMinusOutlierDetection*
        ['k'], # SilhouetteOutlierDetection
        ['k'], # SilhouetteOutlierDetection*

        ['epsilon','minpts','core'], # DBSCANOutlierDetection
        ['minpts', 'minclsize'], # GLOSH
        ['minpts'], # OPTICSOF
        
        ['epsilon','mu','alpha'], # OutRankS1
        ['minpts','minclsize','alpha','subspaces'], # OutRankS1HDBSCAN*
        
        ['numtrees', 'subsample'], # IsolationForest
        ['k'], # KNNOutlier
        ['k'], # LOF
    ]

    sizes = ['1.56perc','3.13perc','6.25perc','12.5perc']

    for method, group in zip(methods, groups):
        # print(method, group)
        for dataset in datasets:
            _means = []
            for size in sizes:
                try:
                    data = pd.read_csv('%s/%s-%s.csv' % (method, dataset, size), comment='#') \
                    .groupby(group).mean() \
                    ['runtime'].values / 1000 # convert to seconds
                    _means.append(np.mean(data))
                except:
                    _means.append(np.nan)
            means.append(np.array(_means))

    #fig, ax = plt.subplots(figsize=(4,4))
    fig, ax = plt.subplots(figsize=(4, 5))

    sizes = ['12.5%','25%','50%','100%']

    n = 1000000
    positions = [int(n*.0156),int(n*.0313),int(n*.0625),int(n*.125)]

    colors = [
        'tab:orange', # EMOutlier
        'tab:blue', # KMeansOutlierDetection
        'tab:pink', # KMeansMinusMinusOutlierDetection
        '#aa8800', # KMeansMinusMinusOutlierDetection*
        'tab:cyan', # SilhouetteOutlierDetection
        '#ff0066', # SilhouetteOutlierDetection*

        'tab:red', # DBSCANOutlierDetection
        'tab:green', # GLOSH
        'tab:purple', # OPTICSOF
        
        'tab:olive', # OutRankS1
        '#508aa8', #OutRankS1HDBSCAN
        
        'darkred', #IsolationForest
        'chocolate', # KNNOutlier
        'silver' # LOF
        ]

    markers = [
        'o', # EMOutlier
        'v', # KMeansOutlierDetection
        '^', # KMeansMinusMinusOutlierDetection
        '<', # KMeansMinusMinusOutlierDetection*
        '>', # SilhouetteOutlierDetection
        '1', # SilhouetteOutlierDetection*
        
        '2', # DBSCANOutlierDetection
        '3', # GLOSH
        '4', # OPTICSOF
        
        's', # OutRankS1
        'p', #OutRankS1HDBSCAN
        
        '*', #IsolationForest
        '+', # KNNOutlier
        'x', # LOF
    ]

    threshold = 18000
    for i, mean in enumerate(means):
        mask = mean <= threshold
        ax.plot(np.log(positions)[mask], mean[mask], marker=markers[i], color=colors[i], fillstyle='none', markersize=8, linewidth=1, linestyle='--')

    xs = np.log(positions[1:3])
    if dimensions == 2:
        ys = [3260.3, 13050.5] # for 2D
    elif dimensions == 10:
        ys = [5260.3, 21050.5] # for 10D
    subtitle = '%d Clusters and Outliers' % n_clusters
    # subtitle = ' '
    slope = (np.log(ys[1])-np.log(ys[0]))/(xs[1]-xs[0])
    print(slope)
    ax.plot(xs, ys, color='gray', linewidth=1.5)
    ys = [0.137, 0.275]
    slope = (np.log(ys[1])-np.log(ys[0]))/(xs[1]-xs[0])
    print(slope)
    ax.plot(xs, ys, color='gray', linewidth=1.5)

    index = [0,1,2,3]
    ax.set_xlabel('Sizes (log)', fontsize=14)
    ax.set_ylabel('Runtime in secs. (log)', fontsize=14)
    ax.set_yscale('log')
    ax.set_xticks(np.log(positions)[index])
    ax.set_xticklabels(np.array(sizes)[index], rotation=0, fontsize=10)

    fig.suptitle(subtitle, fontsize=16, fontweight='bold', y=.98, x=0.56)
    fig.subplots_adjust(
        top=0.894,
        bottom=0.127,
        left=0.206,
        right=0.946,
        hspace=0.2,
        wspace=0.2
    )
    plt.savefig("%s/scalability-%dclusters-%ddim.png" % (path, n_clusters, dimensions), bbox_inches="tight", dpi=300)
    # plt.show()            


algos = [
    'results/outlier.clustering.EMOutlier',
    'results/outlier.clustering.KMeansOutlierDetection',
    'results/outlier.clustering.KMeansMinusMinusOutlierDetection',
    'results/outlier.clustering.KMeansMinusMinusOutlierDetectionStar',
    'results/outlier.clustering.SilhouetteOutlierDetection',
    'results/outlier.clustering.SilhouetteOutlierDetectionStar',
    
    'results/outlier.clustering.DBSCANOutlierDetection',
    'results/outlier.clustering.GLOSH',
    'results/outlier.OPTICSOF',

    'results/outlier.subspace.OutRankS1_D',
    'results/outlier.subspace.OutRankS1_H',
    
    'results/outlier.density.IsolationForest',
    'results/outlier.distance.KNNOutlier',
    'results/outlier.lof.LOF'
]

methods = []
for algo in algos:
    methods.append('%s/Scalability' % algo)

datasets = [
    ['2clusters-noise-2d', 2, 2],
    ['5clusters-noise-2d', 2, 5],
    ['10clusters-noise-2d', 2, 10],

    ['2clusters-noise-10d', 10, 2],
    ['5clusters-noise-10d', 10, 5],
    ['10clusters-noise-10d', 10, 10],
]

for dataset, dimension, n_clusters in tqdm(datasets):
    generate_scalability_plots(
        methods=methods,
        path="experiments/q5_scalability",
        datasets=[dataset],
        dimensions=dimension,
        n_clusters=n_clusters
    )