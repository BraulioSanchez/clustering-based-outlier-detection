import os
import sys

script_dir = os.path.dirname(__file__)
modules_dir = os.path.join(script_dir, '..')
sys.path.append(modules_dir)

import datasets_list

from tqdm import tqdm

import pandas as pd
import numpy as np
import operator
from scipy.stats import wilcoxon
from scipy.stats import friedmanchisquare

import Orange
import matplotlib.pyplot as plt

def wilcoxon_holm(alpha=0.05, df_perf=None):
    """
    Applies the wilcoxon signed rank test between each pair of algorithm and then use Holm
    to reject the null's hypothesis
    """
    # print(pd.unique(df_perf['classifier_name']))
    # count the number of tested datasets per classifier
    df_counts = pd.DataFrame({'count': df_perf.groupby(
        ['classifier_name']).size()}).reset_index()
    # get the maximum number of tested datasets
    max_nb_datasets = df_counts['count'].max()
    # get the list of classifiers who have been tested on nb_max_datasets
    classifiers = list(df_counts.loc[df_counts['count'] == max_nb_datasets]
                       ['classifier_name'])
    # test the null hypothesis using friedman before doing a post-hoc analysis
    friedman_p_value = friedmanchisquare(*(
        np.array(df_perf.loc[df_perf['classifier_name'] == c]['accuracy'])
        for c in classifiers))[1]
    if friedman_p_value >= alpha:
        # then the null hypothesis over the entire classifiers cannot be rejected
        print('the null hypothesis over the entire classifiers cannot be rejected')
        exit()
    # get the number of classifiers
    m = len(classifiers)
    # init array that contains the p-values calculated by the Wilcoxon signed rank test
    p_values = []
    # loop through the algorithms to compare pairwise
    for i in range(m - 1):
        # get the name of classifier one
        classifier_1 = classifiers[i]
        # get the performance of classifier one
        perf_1 = np.array(df_perf.loc[df_perf['classifier_name'] == classifier_1]['accuracy']
                          , dtype=np.float64)
        for j in range(i + 1, m):
            # get the name of the second classifier
            classifier_2 = classifiers[j]
            # get the performance of classifier one
            perf_2 = np.array(df_perf.loc[df_perf['classifier_name'] == classifier_2]
                              ['accuracy'], dtype=np.float64)
            # calculate the p_value
            p_value = wilcoxon(perf_1, perf_2, zero_method='pratt')[1]
            # appen to the list
            p_values.append((classifier_1, classifier_2, p_value, False))
    # get the number of hypothesis
    k = len(p_values)
    # sort the list in acsending manner of p-value
    p_values.sort(key=operator.itemgetter(2))

    # loop through the hypothesis
    for i in range(k):
        # correct alpha with holm
        new_alpha = float(alpha / (k - i))
        # test if significant after holm's correction of alpha
        if p_values[i][2] <= new_alpha:
            p_values[i] = (p_values[i][0], p_values[i][1], p_values[i][2], True)
        else:
            # stop
            break
    # compute the average ranks to be returned (useful for drawing the cd diagram)
    # sort the dataframe of performances
    sorted_df_perf = df_perf.loc[df_perf['classifier_name'].isin(classifiers)]. \
        sort_values(['classifier_name', 'dataset_name'])
    # get the rank data
    rank_data = np.array(sorted_df_perf['accuracy']).reshape(m, max_nb_datasets)

    # create the data frame containg the accuracies
    df_ranks = pd.DataFrame(data=rank_data, index=np.sort(classifiers), columns=
    np.unique(sorted_df_perf['dataset_name']))

    # number of wins
    dfff = df_ranks.rank(ascending=False)
    # print(dfff[dfff == 1.0].sum(axis=1))

    # average the ranks
    average_ranks = df_ranks.rank(ascending=False).mean(axis=1).sort_values(ascending=False)
    # return the p-values and the average ranks
    return p_values, average_ranks, max_nb_datasets

def generate_cdd(_methods, datasets, path,
             index_base_column=0, aggregation="max"):
    columns = ['AUROC', 'Average Precision', 'R-Precision', 'Max-F1']
    base_columns = ['auroc', 'avgprec',\
        'rprec', 'f1']
    # index_base_column = 3

    # aggregation = "max"
    # aggregation = "mean"

    groups = [
        ['epsilon','minpts','core'], # DBSCANOutlierDetection
        ['k'], # EMOutlier
        ['minpts', 'minclsize'], # GLOSH
        ['k'], # KMeansOutlierDetection
        ['k','l'], # KMeansMinusMinusOutlierDetection
        ['k','l'], # KMeansMinusMinusOutlierDetection*
        ['minpts'], # OPTICSOF
        ['epsilon','mu','alpha'], # OutRankS1
        ['minpts','minclsize','alpha','subspaces'], # OutRankS1HDBSCAN*
        ['k'], # SilhouetteOutlierDetection
        ['k'], # SilhouetteOutlierDetection*
        ['numtrees', 'subsample'], # IsolationForest
        ['k'], # KNNOutlier
        ['k'], # LOF
    ]

    values = []
    for method, group in zip(_methods, groups):
        print(method, group)
        measures = []
        for dataset in datasets:
            input = "%s/%s.csv" % (method, dataset)
            try:
                data = pd.read_csv(input, comment='#')[group + base_columns] \
                .groupby(group).mean() \
                .agg(aggregation)
                measures.append(data[base_columns[index_base_column]])
            except:
                print("...", input)
        values.append(measures)

    df_perf = pd.DataFrame(columns=['classifier_name','dataset_name','accuracy'])

    i = 0
    for method in methods:
        for dataset, value in zip(datasets, values[i]):
            df_perf.loc[len(df_perf.index)] = [method, dataset, value]
        i += 1

    _, average_ranks, _ = wilcoxon_holm(df_perf=df_perf, alpha=0.05)

    names = average_ranks.index
    avranks = average_ranks.values

    cd = Orange.evaluation.compute_CD(
        avranks
        , len(np.unique(df_perf['dataset_name']))
        , alpha='0.05'
        , test='nemenyi'
        )
    Orange.evaluation.graph_ranks(avranks, names, cd=cd, reverse=False)

    font = {
            'color':  'black',
            'weight': 'normal',
            'size': 20,
            }
    if (aggregation == "max"):
        plt.title('%s - Best' % columns[index_base_column], fontdict=font)
    elif (aggregation == "mean"):
        plt.title('%s - Average' % columns[index_base_column], fontdict=font)
    plt.savefig("%s/cd-diagram-%s-%s.png" % (path, str(columns[index_base_column]), aggregation), bbox_inches="tight", dpi=300)

methods = [
    'DBSCANOD',
    'EMOutlier',
    'GLOSH',
    'KMeansOD',
    'KMeans--',
    'KMeans--*',
    'OPTICS-OF',
    'OutRank S1/D',
    'OutRank S1/H',
    'SilhouetteOD',
    'SilhouetteOD*',
    'iForest',
    'KNNOutlier',
    'LOF',
]

algos = [
    'results/outlier.clustering.DBSCANOutlierDetection',
    'results/outlier.clustering.EMOutlier',
    'results/outlier.clustering.GLOSH',
    'results/outlier.clustering.KMeansOutlierDetection',
    'results/outlier.clustering.KMeansMinusMinusOutlierDetection',
    'results/outlier.clustering.KMeansMinusMinusOutlierDetectionStar',
    'results/outlier.OPTICSOF',
    'results/outlier.subspace.OutRankS1_D',
    'results/outlier.subspace.OutRankS1_H',
    'results/outlier.clustering.SilhouetteOutlierDetection',
    'results/outlier.clustering.SilhouetteOutlierDetectionStar',
    'results/outlier.density.IsolationForest',
    'results/outlier.distance.KNNOutlier',
    'results/outlier.lof.LOF',
]

_methods = []
for algo in algos:
    _methods.append('%s/Accuracy' % algo)

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
cmd = 'mkdir -p experiments/q1_accuracy/literature'
os.system(cmd)
for aggregation in tqdm(("max", "mean")):
    for i in range(4):
        generate_cdd(_methods, datasets, path="experiments/q1_accuracy/literature",
                    index_base_column=i, aggregation=aggregation)

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
cmd = 'mkdir -p experiments/q1_accuracy/semantic'
os.system(cmd)
for aggregation in tqdm(("max", "mean")):
    for i in range(4):
        generate_cdd(_methods, datasets, path="experiments/q1_accuracy/semantic",
                    index_base_column=i, aggregation=aggregation)

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
cmd = 'mkdir -p experiments/q1_accuracy/synthetic'
os.system(cmd)
for aggregation in tqdm(("max", "mean")):
    for i in range(4):
        generate_cdd(_methods, datasets, path="experiments/q1_accuracy/synthetic",
                    index_base_column=i, aggregation=aggregation)
