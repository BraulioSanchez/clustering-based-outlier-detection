# A Comparative Evaluation of Clustering-based Outlier Detection

by
Braulio V. Sánchez Vinces, Erich Schubert, Arthur Zimek, and and Robson L. F. Cordeiro

# To Cite
    @INPROCEEDINGS{ClusteringOutlier2023,
      author={Braulio V. Sánchez Vinces, Erich Schubert, Arthur Zimek, and and Robson L. F. Cordeiro},
      booktitle={...}, 
      title={A Comparative Evaluation of Clustering-based Outlier Detection}, 
      year={2023}
    }

# Abstract

> In this paper, we perform an extensive experimental evaluation of clustering-based outlier detection methods.
To our knowledge, our work is the first effort to analytically and empirically study the advantages and disadvantages of clustering-based outlier detection techniques.
Our main goal is to evaluate whether or not clustering-based techniques can compete in efficiency and effectiveness against some of the most studied state-of-the-art algorithms in the literature.
To this end, we consider the quality of the results, the resilience against different types of data, the resilience against variations in parameter configuration, the ability of handling large datasets in a reasonable time, and the ability to filter out inappropriate parameter values automatically based on internal measures of clustering quality.
We study 11 clustering-based outlier detectors and 3 non-clustering-based detectors using a consistent parameterization heuristic to evaluate the behavior of the methods with different configurations.
We also study 46 real and synthetic datasets with different characteristics, e.g., datasets with up to 125,000 points or 1,555 dimensions, aiming to achieve plausibility with the broadest possible diversity of real-world use cases in anomaly detection.

# Main Sections
1. [Directory Tree]
2. [Requirements]
3. [Experiments]

## Directory Tree

A summary of the file structure can be found in the following directory tree.

```bash
clustering-based-outlier-detection
├───algorithms // Methods evaluated 
│   ├───binaries // jars
│   ├───codes // Source codes for KMeans--* and OutlRankS1_H implementations
│   │   ├───kmeans--star
│   │   ├───outranks1_h
│   ├───scripts // Scripts in bash for execution of all experiments performed
│   │   ├───for_accuracy
│   │   ├───for_parameter_selection
│   │   ├───for_scalability
├───datasets
│   ├───real // Obtained from Campos et. al (2016)
│   ├───synthetic
│   │   ├───quality
│   │   ├───scalability
├───experiments
│   ├───q1_accuracy
│   ├───q2_resilience_to_data_variation
│   ├───q3_resilience_to_parameter_variation
│   ├───q4_parameter_selection
│   ├───q5_scalability
```

## Requirements

To carry out the experiments, collection and compilation of results, we used a number of open source tools to work properly. The following packages should be installed and/or downloaded before starting

#### Related to Java

- jre8+ - Java Runtime Environment version 8 or more.
- maven - Software project management and comprehension tool.
- elki - Environment for Developing KDD-Applications Supported by Index-Structures version [0.8.0](https://elki-project.github.io/releases/release_notes_0.8.0)

#### Related to Python

- python - Python interpreter in version 3.7 or above.

## Experiments

Before running the experiments, we recommend using [Anaconda](https://docs.anaconda.com/anaconda/install/) to create the environment with all the necessary packages with the following command:

```sh
conda env create -f experiments/environment.yml
conda activate clustering_based_outlier_detection_env
```

And then, to answer each of the research questions, it is necessary to execute the following command:

```sh
python experiments/run.py
```

> Are clustering-based anomaly detection methods competitive in accuracy with those of the non-clustering-based state-of-the-art? (**Q1**),

```sh
python experiments/q1_accuracy/run.py
```

> How resilient to data variation are the evaluated methods? (**Q2**),

```sh
python experiments/q2_resilience_to_data_variation/run.py
```

> How resilient to parameter configuration are the evaluated methods (**Q3**),

```sh
python experiments/q3_resilience_to_parameter_variation/run.py
```

> Does effective clustering imply effective anomaly detection? (**Q4**),

```sh
python experiments/q4_parameter_selection/run.py
```

> How do the methods scale up? (**Q5**),

```sh
python experiments/q5_scalability/run.py
```

_This software was designed in Unix-like systems, it is not yet fully tested in other OS._