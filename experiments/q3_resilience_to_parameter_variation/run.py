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

def generate_plot_all_evaluation_measures(methods,
                                          datasets,
                                          path,
                                          index_base_column = 0,
                                          aggregation = "max",
                                          with_labels = True):
    columns = ['AUROC', 'Average Precision', 'R-Precision', 'Max-F1']
    base_columns = ['auroc', 'adj-avgprec',\
        'adj-rprec', 'adj-f1']
    # index_base_column = 3

    # aggregation = "max"
    # aggregation = "mean"

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
            # print(input)
            try:
                data = pd.read_csv(input, comment='#') \
                .groupby(group).agg("mean") \
                .agg(aggregation) \
                [base_columns]
                values.append(data[base_columns[index_base_column]])
            except:
                print("...", input)
        # print(values)
        measures.append(values)

    # with_labels = True

    if not with_labels:
        fig, ax = plt.subplots(figsize=(6,3.35))
        # fig, ax = plt.subplots(figsize=(6,3.5))
    else:
        fig, ax = plt.subplots(figsize=(6,4.895))
        # fig, ax = plt.subplots(figsize=(6,5.065))

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
    plt.savefig("%s/resilience-%s-%s.png" % (path, str(columns[index_base_column])), bbox_inches="tight", dpi=300)


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
    'ALOI',
    'Glass',
    'Ionosphere',
    'KDDCup99',
    'Lymphography',
    'PenDigits',
    'Shuttle',
    'Waveform',
    'WBC',
    'WDBC',
    'WPBC'
]
cmd = 'mkdir -p experiments/q2_resilience_to_data_variation/literature'
os.system(cmd)
for aggregation in tqdm(["max", "mean"]):
    for i in range(4):
        generate_plot_all_evaluation_measures(
            methods=methods,
            datasets=datasets,
            path='experiments/q2_resilience_to_data_variation/literature',
            index_base_column=i
        )

datasets = [
    'Annthyroid',
    'Arrhythmia',
    'Cardiotocography',
    'HeartDisease',
    'Hepatitis',
    'InternetAds',
    'PageBlocks',
    'Parkinson',
    'Pima',
    'SpamBase',
    'Stamps',
    'Wilt'
]
cmd = 'mkdir -p experiments/q2_resilience_to_data_variation/semantic'
os.system(cmd)
for aggregation in tqdm(["max", "mean"]):
    for i in range(4):
        generate_plot_all_evaluation_measures(
            methods=methods,
            datasets=datasets,
            path='experiments/q2_resilience_to_data_variation/semantic',
            index_base_column=i
        )
    
datasets = [
    '2clusters-10k-2d-random-gaussian-5%global',
    '5clusters-1k-2d-random-gaussian-5%global',
    '5clusters-10k-2d-grid-gaussian-5%global',
    '5clusters-10k-2d-random-gaussian-1%global',
    '5clusters-10k-2d-random-gaussian-5%global', # standard
    '5clusters-10k-2d-random-gaussian-5%local',
    '5clusters-10k-2d-random-gaussian-5%microcluster',
    '5clusters-10k-2d-random-gaussian-10%global',
    '5clusters-10k-2d-random-uniform-5%global',
    '5clusters-10k-2d-sine-gaussian-5%global',
    '5clusters-10k-5d-random-gaussian-5%global',
    '5clusters-10k-10d-random-gaussian-5%global',
    '5clusters-10k-12d2irr-random-gaussian-5%global',
    '5clusters-10k-15d5irr-random-gaussian-5%global',
    '5clusters-10k-20d10irr-random-gaussian-5%global',
    '5clusters-50k-2d-random-gaussian-5%global',
    '10clusters-10k-2d-random-gaussian-5%global',
]
cmd = 'mkdir -p experiments/q2_resilience_to_data_variation/synthetic'
os.system(cmd)
for aggregation in tqdm(["max", "mean"]):
    for i in range(4):
        generate_plot_all_evaluation_measures(
            methods=methods,
            datasets=datasets,
            path='experiments/q2_resilience_to_data_variation/synthetic',
            index_base_column=i
        )