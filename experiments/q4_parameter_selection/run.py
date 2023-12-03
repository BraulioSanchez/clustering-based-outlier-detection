from tqdm import tqdm

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from scipy import stats

def pearsonr_ci(x,y,alpha=0.05):
    ''' calculate Pearson correlation along with the confidence interval using scipy and numpy
    Parameters
    ----------
    x, y : iterable object such as a list or np.array
      Input for correlation calculation
    alpha : float
      Significance level. 0.05 by default
    Returns
    -------
    r : float
      Pearson's correlation coefficient
    pval : float
      The corresponding p value
    lo, hi : float
      The lower and upper bound of confidence intervals
    '''

    r, p = stats.pearsonr(x,y)
    r_z = np.arctanh(r)
    se = 1/np.sqrt(x.size-3)
    z = stats.norm.ppf(1-alpha/2)
    lo_z, hi_z = r_z-z*se, r_z+z*se
    lo, hi = np.tanh((lo_z, hi_z))
    return r, p, lo, hi

def process_results(datasets, outlier_criterion, cluster_criterion,
                    clustering_evaluation = "dbcv"):
    if clustering_evaluation == "dbcv":
        columns_ = ['dbcv', 'auroc', 'adj-avgprec', 'adj-rprec', 'adj-f1', 'epsilon', 'minpts'] # DBSCAN, DBSCANOD
    elif clustering_evaluation == "asw":
        columns_ = ['silhouette', 'auroc', 'adj-avgprec', 'adj-rprec', 'adj-f1', 'k'] # KMeans, SilhouetteOD

    measures = ['auroc', 'adj-avgprec', 'adj-rprec', 'adj-f1']

    threshold = 0.

    if clustering_evaluation == "dbcv":
        validator, columns = 'dbcv', ['epsilon','minpts','dbcv'] + measures
    elif clustering_evaluation == "asw":
        validator, columns = 'silhouette', ['k','silhouette'] + measures

    conf_intv_auroc = []
    conf_intv_avgprec = []
    conf_intv_rprec = []
    conf_intv_f1 = []
    _clustering = []
    _outlier = []
    _avgprecs = []
    _rprecs = []
    _f1s = []

    for dataset, _ in datasets:
        outlier_data = pd.read_csv('{}/{}.csv'.format(outlier_criterion, dataset), comment='#')
        cluster_data = pd.read_csv('{}/{}.csv'.format(cluster_criterion, dataset), comment='#')
        
        data = outlier_data.merge(cluster_data, on=columns_[5:])[columns_] \
            .groupby(by=columns_[5:]).mean().reset_index()

        subset = data.loc[:,columns].dropna()
        if subset[validator].max() >= threshold:
            _, _, lo, hi = pearsonr_ci(subset[validator], subset['auroc'])
            _, _, lo1, hi1 = pearsonr_ci(subset[validator], subset['adj-avgprec'])
            _, _, lo2, hi2 = pearsonr_ci(subset[validator], subset['adj-rprec'])
            _, _, lo3, hi3 = pearsonr_ci(subset[validator], subset['adj-f1'])

        conf_intv_auroc.append([lo, hi])
        conf_intv_avgprec.append([lo1, hi1])
        conf_intv_rprec.append([lo2, hi2])
        conf_intv_f1.append([lo3, hi3])
        _clustering.append(subset[validator].values)
        _outlier.append(subset['auroc'].values)
        _avgprecs.append(subset['adj-avgprec'].values)
        _rprecs.append(subset['adj-rprec'].values)
        _f1s.append(subset['adj-f1'].values)

    return conf_intv_auroc, conf_intv_avgprec, conf_intv_rprec, conf_intv_f1, \
            _clustering, _outlier, _avgprecs, _rprecs, _f1s

def plot_conf_intv(conf_intv_auroc, conf_intv_avgprec, conf_intv_rprec, conf_intv_f1,
        path,
        index_base_column = 0,
        clustering_evaluation = "dbcv"):
    columns = ['AUROC', 'Average Precision', 'R-Precision', 'Max-F1']
    # Confidence interval - 2nd version
    _, ax = plt.subplots(figsize=(7*1.3,8*.57))

    ax.axhline(0., color='k', linestyle=':')
    if index_base_column == 0:
        conf_intv = conf_intv_auroc
    elif index_base_column == 1:
        conf_intv = conf_intv_avgprec
    elif index_base_column == 2:
        conf_intv = conf_intv_rprec
    elif index_base_column == 3:
        conf_intv = conf_intv_f1

    for x,y in zip(datasets, conf_intv):
        mean = (y[1]-y[0])*0.5 + y[0]
        ax.plot(x, y, lw=1.5*1.2, color='k', marker='_', ms=10*1.2)
        ax.scatter(x[0], mean, color='#ff0000', s=30)
        _x = x[0]
    ax.scatter(_x, mean, color='#ff0000', s=30, label='average')
    ax.legend(fontsize=14,framealpha=1,frameon=False)

    ax.set_yticks([-1., -.5, 0., .5, 1.])
    ax.set_yticklabels(ax.get_yticks(), rotation=0, fontsize=12)
    xticklabels = []
    for i in datasets:
        xticklabels.append(i[0])
    ax.set_xticklabels(xticklabels, rotation=90, fontsize=14)

    if clustering_evaluation == "dbcv":
        clustering_evaluation = "DBCV"
    elif clustering_evaluation == "asw":
        clustering_evaluation = "ASW"
    ax.set_ylabel('Confidence Interval\n(%s vs %s)' % (clustering_evaluation, columns[index_base_column]), fontsize=16)
    ax.set_ylim((-1.,1.0))

    plt.tight_layout()
    font = {
            'color':  'black',
            'weight': 'normal',
            'size': 20,
            }
    plt.title('%s' % columns[index_base_column], fontdict=font)
    plt.savefig("%s/conf_intv-%s-%s.png" % (path, clustering_evaluation, columns[index_base_column]), bbox_inches="tight", dpi=300)

def plot_clustering_quality(_outlier, _clustering, _avgprecs, _rprecs, _f1s,
        path,
        index_base_column = 0,
        clustering_evaluation = "dbcv"):
    columns = ['AUROC', 'Average Precision', 'R-Precision', 'Max-F1']
    # Scatter - Better clustering quality within Outliers evaluation measures

    fig, ax = plt.subplots(figsize=(7*1.3,5*.57))

    if index_base_column == 0:
        measures = _outlier
        ax.axhline(0.5, color='k', linestyle=':')
    elif index_base_column == 1:
        measures = _avgprecs
    elif index_base_column == 2:
        measures = _rprecs
    elif index_base_column == 3:
        measures = _f1s

    for dataset, measure, c in zip(datasets, measures, _clustering):
        maxval = np.max(c)
        mask = c == maxval
        ax.scatter([dataset[0]]*len(measure), measure, s=35, marker='o', color='#003d7a', alpha=.75, edgecolors='k', linewidths=.78)
        ax.scatter([dataset[0]]*len(c[mask]), measure[mask], s=110, marker='_', color='#ff0000')
        _x, _y = dataset[0], measure[mask][0]
    ax.scatter(_x, _y, color='#ff0000', s=110, marker='_', label='best\nclustering\nquality')
    ax.legend(fontsize=14,framealpha=1,frameon=False)

    # if with_auroc or with_avgprec or with_rprec or with_f1:
    if clustering_evaluation == "dbcv":
        ax.set_yticks([.0, .2, .4, .6, .8, 1])
    else:
        ax.set_yticks([-1., -.5, 0., .5, 1.])
    ax.set_yticklabels(ax.get_yticks(), rotation=0, fontsize=12)
    # ax.set_xticklabels([' ']*len(datasets), rotation=90, fontsize=12)
    xticklabels = []
    for i in datasets:
        xticklabels.append(i[0])
    ax.set_xticklabels(xticklabels, rotation=90, fontsize=14)

    if index_base_column == 0:
        ax.set_ylabel('AUROC', fontsize=16);
    elif index_base_column == 1:
        ax.set_ylabel('Avg. Prec.', fontsize=16);
    elif index_base_column == 2:
        ax.set_ylabel('R-Prec', fontsize=16);
    elif index_base_column == 3:
        ax.set_ylabel('Max-F1', fontsize=16);
    ax.set_ylim((.0, 1.))

    if clustering_evaluation == "dbcv":
        clustering_evaluation = "DBCV"
    elif clustering_evaluation == "asw":
        clustering_evaluation = "ASW"

    fig.subplots_adjust(
        top=0.926,
        bottom=0.105,
        left=0.105,
        right=0.979,
        hspace=0.2,
        wspace=0.2    
    )

    font = {
            'color':  'black',
            'weight': 'normal',
            'size': 20,
            }
    plt.title('%s' % columns[index_base_column], fontdict=font)
    plt.savefig("%s/clust_quality-%s-%s.png" % (path, clustering_evaluation, columns[index_base_column]), bbox_inches="tight", dpi=300)  

path = 'q4_parameter_selection'

datasets = [
    ['ALOI','ALOI'],
    ['Glass','Glass'],
    ['Ionosphere','Ionosphere'],
    ['KDDCup99','KDDCup99'],
    ['Lymphography','Lymphography'],
    ['PenDigits','PenDigits'],
    ['Shuttle','Shuttle'],
    ['Waveform','Waveform'],
    ['WBC','WBC'],
    ['WDBC','WDBC'],
    ['WPBC','WPBC'],
    ['Annthyroid','Annthyroid'],
    ['Arrhythmia','Arrhythmia'],
    ['Cardiotocography','Cardiotocography'],
    ['HeartDisease','HeartDisease'],
    ['Hepatitis','Hepatitis'],
    ['InternetAds','InternetAds'],
    ['PageBlocks','PageBlocks'],
    ['Parkinson','Parkinson'],
    ['Pima','Pima'],
    ['SpamBase','SpamBase'],
    ['Stamps','Stamps'],
    ['Wilt','Wilt'],
]

method = 'results/outlier.clustering.SilhouetteOutlierDetection'
outlier_criterion = '%s/Accuracy' % method
method = 'results/clustering.kmeans.HamerlyKMeans'
cluster_criterion = '%s/clustering.internal.Silhouette' % method
conf_intv_auroc, conf_intv_avgprec, conf_intv_rprec, conf_intv_f1, \
            _clustering, _outlier, _avgprecs, _rprecs, _f1s = process_results(
    datasets=datasets,
    outlier_criterion=outlier_criterion,
    cluster_criterion=cluster_criterion,
    clustering_evaluation="asw"
)
for i in tqdm(range(4), desc="Generating plots for k-means / SilhouetteOD"):
    plot_conf_intv(
       conf_intv_auroc=conf_intv_auroc,
       conf_intv_avgprec=conf_intv_avgprec,
       conf_intv_rprec=conf_intv_rprec,
       conf_intv_f1=conf_intv_f1,
       path='experiments/%s' % path,
       clustering_evaluation="asw",
       index_base_column=i
    )
    plot_clustering_quality(
        _outlier=_outlier,
        _clustering=_clustering,
        _avgprecs=_avgprecs,
        _rprecs=_rprecs,
        _f1s=_f1s,
        path='experiments/%s' % path,
       clustering_evaluation="asw",
       index_base_column=i
    )

method = 'results/outlier.clustering.DBSCANOutlierDetection'
outlier_criterion = '%s/Accuracy' % method
method = 'results/clustering.dbscan.GeneralizedDBSCAN'
cluster_criterion = '%s/clustering.internal.DBCV' % method
conf_intv_auroc, conf_intv_avgprec, conf_intv_rprec, conf_intv_f1, \
            _clustering, _outlier, _avgprecs, _rprecs, _f1s = process_results(
    datasets=datasets,
    outlier_criterion=outlier_criterion,
    cluster_criterion=cluster_criterion,
    clustering_evaluation="dbcv"
)
for i in tqdm(range(4), desc="Generating plots for DBSCAN / DBSCANOD"):
    plot_conf_intv(
       conf_intv_auroc=conf_intv_auroc,
       conf_intv_avgprec=conf_intv_avgprec,
       conf_intv_rprec=conf_intv_rprec,
       conf_intv_f1=conf_intv_f1,
       path='experiments/%s' % path,
       clustering_evaluation="dbcv",
       index_base_column=i
    )
    plot_clustering_quality(
        _outlier=_outlier,
        _clustering=_clustering,
        _avgprecs=_avgprecs,
        _rprecs=_rprecs,
        _f1s=_f1s,
        path='experiments/%s' % path,
       clustering_evaluation="dbcv",
       index_base_column=i
    )