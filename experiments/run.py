import os
import sys

script_dir = os.path.dirname(__file__)
modules_dir = os.path.join(script_dir, '..')
sys.path.append(modules_dir)

import datasets_list

import pandas as pd
import numpy as np
from tqdm import tqdm

methods_for_accuracy = [
    ["DBSCANOD", "dbscanod", "algorithms/scripts/for_accuracy/hysortod.sh"],
    ["EMOutlier", "emoutlier", "algorithms/scripts/for_accuracy/emoutlier.sh"],
    ["GLOSH", "glosh", "algorithms/scripts/for_accuracy/glosh.sh"],
    ["KMeansOD", "kmeansod", "algorithms/scripts/for_accuracy/kmeansod.sh"],
    ["KMeans--", "kmeans--", "algorithms/scripts/for_accuracy/kmeans--.sh"],
    ["KMeans--*", "kmeans--star", "algorithms/scripts/for_accuracy/kmeans--star.sh"],
    ["OPTICS-OF", "opticsof", "algorithms/scripts/for_accuracy/opticsof.sh"],
    ["OutRank S1/D", "outranks1_d", "algorithms/scripts/for_accuracy/outranks1_d.sh"],
    ["OutRank S1/D", "outranks1_h", "algorithms/scripts/for_accuracy/outranks1_h.sh"],
    ["SilhouetteOD", "silhouetteoutlier", "algorithms/scripts/for_accuracy/silhouetteoutlier.sh"],
    ["SilhouetteOD*", "silhouetteoutlierstar", "algorithms/scripts/for_accuracy/silhouetteoutlierstar.sh"],
    ["iForest", "iforest", "algorithms/scripts/for_accuracy/iforest.sh"],
    ["KNNOutlier", "knnoutlier", "algorithms/scripts/for_accuracy/knnoutlier.sh"],
    ["LOF", "lof", "algorithms/scripts/for_accuracy/lof.sh"],
]
for _, _, script in tqdm(methods_for_accuracy):
    cmd = "sh %s" % script
    # os.system(cmd)
print("Runs for accuracy results concluded!")


methods_for_parameter_selection = [
    ["DBSCAN", "dbscan", "algorithms/scripts/for_parameter_selection/hysortod.sh"],
    ["DBSCANOD", "dbscanod", "algorithms/scripts/for_parameter_selection/hysortod.sh"],
    ["KMeans", "hamerlykmeans", "algorithms/scripts/for_parameter_selection/hamerlykmeans.sh"],
    ["SilhouetteOD", "silhouetteoutlier", "algorithms/scripts/for_parameter_selection/silhouetteoutlier.sh"],
]
for _, _, script in tqdm(methods_for_accuracy):
    cmd = "sh %s" % script
    # os.system(cmd)
print("Runs for parameter selection results concluded!")

methods_for_scalability = [
    ["DBSCANOD", "dbscanod", "algorithms/scripts/for_scalability/hysortod.sh"],
    ["EMOutlier", "emoutlier", "algorithms/scripts/for_scalability/emoutlier.sh"],
    ["GLOSH", "glosh", "algorithms/scripts/for_scalability/glosh.sh"],
    ["KMeansOD", "kmeansod", "algorithms/scripts/for_scalability/kmeansod.sh"],
    ["KMeans--", "kmeans--", "algorithms/scripts/for_scalability/kmeans--.sh"],
    ["KMeans--*", "kmeans--star", "algorithms/scripts/for_scalability/kmeans--star.sh"],
    ["OPTICS-OF", "opticsof", "algorithms/scripts/for_scalability/opticsof.sh"],
    ["OutRank S1/D", "outranks1_d", "algorithms/scripts/for_scalability/outranks1_d.sh"],
    ["OutRank S1/D", "outranks1_h", "algorithms/scripts/for_scalability/outranks1_h.sh"],
    ["SilhouetteOD", "silhouetteoutlier", "algorithms/scripts/for_scalability/silhouetteoutlier.sh"],
    ["SilhouetteOD*", "silhouetteoutlierstar", "algorithms/scripts/for_scalability/silhouetteoutlierstar.sh"],
    ["iForest", "iforest", "algorithms/scripts/for_scalability/iforest.sh"],
    ["KNNOutlier", "knnoutlier", "algorithms/scripts/for_scalability/knnoutlier.sh"],
    ["LOF", "lof", "algorithms/scripts/for_scalability/lof.sh"],
]
for _, _, script in tqdm(methods_for_accuracy):
    cmd = "sh %s" % script
    # os.system(cmd)
print("Runs for scalability results concluded!")