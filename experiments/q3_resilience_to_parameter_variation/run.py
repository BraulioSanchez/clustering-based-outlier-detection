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

def process_results(index_base_column = 0):
    base_columns = ['auroc', 'adj-avgprec',\
        'adj-rprec', 'adj-f1']

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

    measures = []
    for method, group in zip(methods, groups):
        print(method, group)
        values = []
        for dataset in datasets:
            input = "%s/%s.csv" % (method, dataset)
            try:
                data = pd.read_csv(input, comment='#')
                data = data \
                .groupby(group).agg("mean") \
                [base_columns]
                values += data[base_columns[index_base_column]].values.tolist()
            except:
                print("...", input)
        measures.append(values)

    return measures

def plot(measures, path,
        with_labels=True, index_base_column = 0):
    columns = ['AUROC', 'Average Precision', 'R-Precision', 'Max-F1']
    if not with_labels:
        fig, ax = plt.subplots(figsize=(6,3.35))
    else:
        fig, ax = plt.subplots(figsize=(6,4.895))

    titles = ["AUROC", "Average Precision", "R-Precision", "Max-F1"]

    colors = [
        'tab:orange', #EMOutlier
        'tab:blue', #KMeansOutlierDetection
        'tab:pink', #KMeansMinusMinusOutlierDetection
        '#aa8800', # KMeansMinusMinusOutlierDetection*
        'tab:cyan', #SilhouetteOutlierDetection
        '#ff0066', # SilhouetteOutlierDetection*

        'tab:red', #DBSCANOutlierDetection
        'tab:green', #GLOSH
        'tab:purple', #OPTICSOF
        
        'tab:olive', #OutRankS1
        '#508aa8', #OutRankS1HDBSCAN
        
        'darkred', #IsolationForest
        'chocolate', #KNNOutlier
        'silver', #LOF
        ]

    labels = [
        'EMOutlier',
        'KMeansOD',
        'KMeans--',
        'KMeans--*',
        'SilhouetteOD',
        'SilhouetteOD*',

        'DBSCANOD',
        'GLOSH',
        'OPTICS-OF',
        
        'OutRank S1/D',
        'OutRank S1/H',
        
        'iForest',
        'KNNOutlier',
        'LOF'
        ]

    if not with_labels:
        bplot = ax.boxplot(
            measures,
            patch_artist=True,
            showmeans=False, showfliers=True,
            widths=0.35,
            medianprops={"color": "white", "linewidth": 2},
            whiskerprops={"color": "k", "linewidth": 2},
            capprops={"color": "k", "linewidth": 2}
        )
    else:
        bplot = ax.boxplot(
            measures,
            labels=labels,
            patch_artist=True,
            showmeans=False, showfliers=True,
            widths=0.35,
            medianprops={"color": "white", "linewidth": 2},
            whiskerprops={"color": "k", "linewidth": 2},
            capprops={"color": "k", "linewidth": 2}
        )
    for box,flier,whisker,color in zip(bplot['boxes'],bplot['fliers'],bplot['whiskers'],colors):
        box.set_facecolor(color); box.set_linewidth(1.5); box.set_edgecolor(color)
        flier.set_markerfacecolor(color); flier.set_markeredgecolor(color); flier.set_markeredgewidth(0.4); flier.set_markersize(6)

    if not with_labels:
        ax.set_xticks([])
        ax.set_xticklabels([])
    else:
        ax.set_xticklabels(labels, rotation=90, fontsize=16)
    ax.set_yticks([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
    ax.set_yticklabels(ax.get_yticks(), rotation=0, fontsize=16)
    ax.yaxis.grid(True)

    ax.set_ylim((0.0, 1.0))

    font = {
            'color':  'black',
            'weight': 'normal',
            'size': 20,
            }

    plt.tight_layout()
    plt.title('%s' % columns[index_base_column], fontdict=font)
    plt.savefig("%s/resilience-%s.png" % (path, str(columns[index_base_column])), bbox_inches="tight", dpi=300)

def process_results_(datasets,
        index_base_column = 0):
    base_columns = ['auroc', 'adj-avgprec',\
        'adj-rprec', 'adj-f1']

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

    means = []
    stddevs = []
    for dataset in datasets:
        print(dataset)
        _means = []
        _stddevs = []
        for method, group in zip(methods, groups):
            input = "%s/%s.csv" % (method, dataset)
            try:
                data = pd.read_csv(input, comment='#')
                data = data \
                .groupby(group).agg("mean") \
                [base_columns]
                _means.append(data[base_columns[index_base_column]] \
                .values.mean())
                _stddevs.append(data[base_columns[index_base_column]] \
                .values.std())
            except:
                print("...", input)
        means.append(_means)
        stddevs.append(_stddevs)

    return means, stddevs

def plot_(means, stddevs, markers, path,
          index_base_column = 0,
          difficulty = "low",
          with_ylabel = True,
          with_xlabel = True,
          with_auroc = True):
    columns = ['AUROC', 'Average Precision', 'R-Precision', 'Max-F1']

    if not with_xlabel:
        fig, ax = plt.subplots(figsize=(5.91,3.5))
    else:
        fig, ax = plt.subplots(figsize=(5.91,3.91))

    colors = [
        'tab:orange', #EMOutlier
        'tab:blue', #KMeansOutlierDetection
        'tab:pink', #KMeansMinusMinusOutlierDetection
        '#aa8800', #KMeansMinusMinusOutlierDetection*
        'tab:cyan', #SilhouetteOutlierDetection
        '#ff0066', #SilhouetteOutlierDetection*

        'tab:red', #DBSCANOutlierDetection
        'tab:green', #GLOSH
        'tab:purple', #OPTICSOF

        'tab:olive', #OutRankS1
        '#508aa8', #OutRankS1HDBSCAN
        
        'darkred', #IsolationForest
        'chocolate', #KNNOutlier
        'silver', #LOF
        ]

    labels = [
        'EMOutlier',
        'KMeansOD',
        'KMeans--',
        'KMeans--*',
        'SilhouetteOD',
        'SilhouetteOD*',

        'DBSCANOD',
        'GLOSH',
        'OPTICS-OF',
        
        'OutRank S1/D',
        'OutRank S1/H',
        
        'iForest',
        'KNNOutlier',
        'LOF'
        ]

    for _means, _stddevs, marker in zip(means, stddevs, markers):
        for mean, stddev, color in zip(_means, _stddevs, colors):
            ax.scatter(mean, stddev, marker=marker[0], facecolors='none', edgecolors=color, s=marker[1], linewidths=2)
    if with_auroc:
        ax.axvline(0.5, color='k', linestyle='--')

    ax.set_xticks([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
    ax.set_xticklabels(ax.get_xticks(), rotation=0, fontsize=16)
    ax.set_yticks([0.0, 0.1, 0.2, 0.3, 0.4])
    ax.set_yticklabels(ax.get_yticks(), rotation=0, fontsize=16)
    ax.yaxis.grid(True)

    ax.set_xlim((0.0, 1.0))
    ax.set_ylim((0.0, 0.4))

    if with_ylabel:
        ax.set_ylabel('Standard Deviation', fontsize=16)
    if with_xlabel:
        ax.set_xlabel('Average', fontsize=16)

    if not with_xlabel:
        fig.subplots_adjust(
            top=0.931,
            bottom=0.136,
            left=0.136,
            right=0.946,
            hspace=0.2,
            wspace=0.2
        )
    else:
        fig.subplots_adjust(
            top=0.931,
            bottom=0.166,
            left=0.136,
            right=0.946,
            hspace=0.2,
            wspace=0.2
        )

    font = {
            'color':  'black',
            'weight': 'normal',
            'size': 20,
            }
    plt.title('%s' % columns[index_base_column], fontdict=font)
    plt.savefig("%s/overall_view-%s-%s.png" % (path, str(columns[index_base_column]), difficulty), bbox_inches="tight", dpi=300)

path = 'q3_resilience_to_parameter_variation'

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
    'results/outlier.lof.LOF',
]

methods = []
for algo in algos:
    methods.append('%s/Accuracy' % algo)

datasets = [
    # 'ALOI',
    # 'Glass',
    # 'Ionosphere',
    # 'KDDCup99',
    'Lymphography',
    # 'PenDigits',
    # 'Shuttle',
    # 'Waveform',
    # 'WBC',
    # 'WDBC',
    # 'WPBC'
]
cmd = 'mkdir -p experiments/%s/literature' % path
os.system(cmd)
for i in tqdm(range(4), desc="Generating plots for datasets used in literature"):
    measures = process_results(
        index_base_column=i,
    )
    plot(
        measures=measures,
        path='experiments/%s/literature' % path,
        index_base_column=i
    )

datasets = [
    # 'Annthyroid',
    # 'Arrhythmia',
    # 'Cardiotocography',
    # 'HeartDisease',
    # 'Hepatitis',
    # 'InternetAds',
    # 'PageBlocks',
    # 'Parkinson',
    # 'Pima',
    # 'SpamBase',
    # 'Stamps',
    'Wilt'
]
cmd = 'mkdir -p experiments/%s/semantic' % path
os.system(cmd)
for i in tqdm(range(4), desc="Generating plots for datasets semantically meaningful"):
    measures = process_results(
        index_base_column=i,
    )
    plot(
        measures=measures,
        path='experiments/%s/semantic' % path,
        index_base_column=i
    )

# Overall view
datasets = [
    'Lymphography',
    'Parkinson',
    'WBC',
    'WDBC',
]

markers = [
    ('v',120+20), #Lymphography
    ('^',120+20), #Parkinson
    ('s',120+20), #WBC
    ('p',120+20), #WDBC
]
cmd = 'mkdir -p experiments/%s/low_diff' % path
os.system(cmd)
for i in tqdm(range(4), desc="Generating plots for datasets with low difficulty"):
    means, stddevs = process_results_(
        datasets=datasets,
        index_base_column=i,
    )
    plot_(
        means=means,
        stddevs=stddevs,
        markers=markers,
        path='experiments/%s/low_diff' % path,
        index_base_column=i,
        difficulty="low"
    )

datasets = [
    'PageBlocks',
    'Stamps',
    'HeartDisease',
    'Hepatitis',
    'Arrhythmia',
    'InternetAds',
    'Glass',
    'Cardiotocography',
]

markers = [
    ('P',120+20), #PageBlocks
    ('*',180+20), #Stamps
    (r"$\heartsuit$",180+20), #HeartDisease
    (r"$\S$",180+20), #Hepatitis
    (r"$\Phi$",180+20),# 'Arrhythmia',
    ('X',120+20),# 'InternetAds',
    (r"$\varnothing$",140+20),# 'Glass',
    (r"$\sharp$",280+20),# 'Cardiotocography',
]
cmd = 'mkdir -p experiments/%s/medium_diff' % path
os.system(cmd)
for i in tqdm(range(4), desc="Generating plots for datasets with medium difficulty"):
    means, stddevs = process_results_(
        datasets=datasets,
        index_base_column=i,
    )
    plot_(
        means=means,
        stddevs=stddevs,
        markers=markers,
        path='experiments/%s/medium_diff' % path,
        index_base_column=i,
        difficulty="medium"
    )

datasets = [
    'SpamBase',
    'Pima',
    'ALOI',
    'Annthyroid',
    'Wilt',
    'Waveform',
]

markers = [
    ("<",140+20),# 'SpamBase',
    (r"$\clubsuit$",180+20),# 'Pima',
    (r"$\diamondsuit$",180+20),# 'ALOI',
    (">",140+20),# 'Annthyroid',
    ('h',120+20),# 'Wilt',
    (r"$\spadesuit$",180+20),# 'Waveform',
]
cmd = 'mkdir -p experiments/%s/high_diff' % path
os.system(cmd)
for i in tqdm(range(4), desc="Generating plots for datasets with high difficulty"):
    means, stddevs = process_results_(
        datasets=datasets,
        index_base_column=i,
    )
    plot_(
        means=means,
        stddevs=stddevs,
        markers=markers,
        path='experiments/%s/high_diff' % path,
        index_base_column=i,
        difficulty="high"
    )