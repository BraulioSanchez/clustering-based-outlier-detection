#!/bin/bash

#$((1 + RANDOM % 2147483647))
javaCommand="java -Xmx30G -jar algorithms/binaries/elki-0.8.0.jar KDDCLIApplication"
algorithm="outlier.clustering.DBSCANOutlierDetection"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

evaluator="Adaptive"
csvFile="$results/$algorithm/$evaluator/result.csv"
[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
# echo "# $(date) - $evaluator" >> "$csvFile"
echo "dataset,epsilon,minpts,core,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

############ 11 datasets used in the literature ############
_literature() {
	dataset="ALOI"
	labelColumn=27
	epsilon=0.269161
	minpts=6
	process_dataset "$dataset" "$labelColumn" "$epsilon" "$minpts"
	
	dataset="Glass"
	labelColumn=7
	epsilon=0.257696
	minpts=13
	process_dataset "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Ionosphere"
	labelColumn=32
	epsilon=0.572474
	minpts=15
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="KDDCup99"
	labelColumn=38
	epsilon=0.225618
	minpts=750
	process_dataset "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Lymphography"
	labelColumn=3
	epsilons=(0.01732051 0.0239023 0.03048409 0.03706589 0.04364768 0.05022947 0.05681127 0.06339306 0.06997485 0.07655665 0.08313844 0.08972023 0.09630202 0.10288382 0.10946561 0.1160474 0.1226292 0.12921099 0.13579278 0.14237458)
	for epsilon in "${epsilons[@]}"; do
		for minpts in {1..2}; do
			process_dataset "$dataset" "$labelColumn" "$epsilon" "$minpts"
		done
	done

	dataset="PenDigits"
	labelColumn=16
	epsilon=73.92
	minpts=31
	process_dataset_10versions "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Shuttle"
	labelColumn=9
	epsilon=0.2238
	minpts=17
	process_dataset_10versions "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Waveform"
	labelColumn=21
	epsilon=0.515998
	minpts=5
	process_dataset_10versions "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="WBC"
	labelColumn=9
	epsilon=0.6
	minpts=2
	process_dataset_10versions "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="WDBC"
	labelColumn=30
	epsilon=0.408601
	minpts=7
	process_dataset_10versions "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="WPBC"
	labelColumn=33
	epsilon=0.603179
	minpts=8
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"
}

# ############ 12 datasets semantically meaningful ############
_semantic() {
	dataset="Annthyroid"
	labelColumn=21
	epsilon=0.185136
	minpts=10
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Arrhythmia"
	labelColumn=259
	epsilon=-
	minpts=-
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Cardiotocography"
	labelColumn=21
	epsilon=0.550826
	minpts=5
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="HeartDisease"
	labelColumn=13
	epsilon=0.707409
	minpts=3
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Hepatitis"
	labelColumn=19
	epsilon=-
	minpts=-
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="InternetAds"
	labelColumn=1555
	epsilon=-
	minpts=-
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="PageBlocks"
	labelColumn=10
	epsilon=0.187839
	minpts=9
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Parkinson"
	labelColumn=22
	epsilon=0.617259
	minpts=5
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Pima"
	labelColumn=8
	epsilon=0.318481
	minpts=7
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="SpamBase"
	labelColumn=57
	epsilon=0.333703
	minpts=14
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Stamps"
	labelColumn=9
	epsilon=0.201
	minpts=8
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"

	dataset="Wilt"
	labelColumn=5
	epsilons=(0.22629008 0.23478714 0.2432842 0.25178125 0.26027831 0.26877537)
	for epsilon in "${epsilons[@]}"; do
		for minpts in {1..2}; do
			process_dataset_5perc "$dataset" "$labelColumn" "$epsilon" "$minpts"
		done
	done
}

process_dataset() {
	local dataset="$1"
    local labelColumn=$2
	local epsilon=$3
	local minpts=$4

	$javaCommand -algorithm $algorithm \
		-time \
		-dbc.in datasets/real/$dataset\_withoutdupl\_norm.arff \
		-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
		-dbscan.epsilon $epsilon \
		-gdbscan.core-model true \
		-dbscan.minpts $minpts > $algorithm-$dataset.out
	awk -v dataset=$dataset '/dbscan.epsilon|dbscan.minpts|gdbscan.core-model|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
		if (/dbscan.epsilon/) {
			dbscan_epsilon = $NF;  # assuming the value is in the last field
		} else if (/dbscan.minpts/) {
			dbscan_minpts = $NF;
		} else if (/gdbscan.core-model/) {
			gdbscan_coremodel = $NF;
		} else if (/measures AUROC/) {
			auroc = $NF;
		} else if (/Adjusted AUROC/) {
			adj_auroc = $NF;
		} else if (/measures AUPRC/) {
			auprc = $NF;
		} else if (/Adjusted AUPRC/) {
			adj_auprc = $NF;
		} else if (/measures AUPRGC/) {
			auprgc = $NF;
		} else if (/Adjusted AUPRGC/) {
			adj_auprgc = $NF;
		} else if (/measures Average Precision/) {
			avg_prec = $NF;
		} else if (/Adjusted AveP/) {
			adj_avg_prec = $NF;
		} else if (/measures R-Precision/) {
			rprec = $NF;
		} else if (/Adjusted R-Prec/) {
			adj_rprec = $NF;
		} else if (/measures Maximum F1/) {
			max_f1 = $NF;
		} else if (/Adjusted Max F1/) {
			adj_max_f1 = $NF;
		} else if (/measures DCG/) {
			dcg = $NF;
		} else if (/Adjusted DCG/) {
			adj_dcg = $NF;
		} else if (/measures NDCG/) {
			ndcg = $NF;
		} else if (/runtime: /) {
			runtime = $(NF-1);
		}
	} END {
		print dataset","dbscan_epsilon","dbscan_minpts","gdbscan_coremodel","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
	}' $algorithm-$dataset.out >> $csvFile
	rm $algorithm-$dataset.out	
}

process_dataset_5perc() {
	local dataset="$1"
    local labelColumn=$2
	local epsilon=$3
	local minpts=$4

	$javaCommand -algorithm $algorithm \
		-time \
		-dbc.in datasets/real/$dataset\_withoutdupl\_norm\_05.arff \
		-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
		-dbscan.epsilon $epsilon \
		-gdbscan.core-model true \
		-dbscan.minpts $minpts > $algorithm-$dataset.out
	awk -v dataset=$dataset '/dbscan.epsilon|dbscan.minpts|gdbscan.core-model|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
		if (/dbscan.epsilon/) {
			dbscan_epsilon = $NF;  # assuming the value is in the last field
		} else if (/dbscan.minpts/) {
			dbscan_minpts = $NF;
		} else if (/gdbscan.core-model/) {
			gdbscan_coremodel = $NF;
		} else if (/measures AUROC/) {
			auroc = $NF;
		} else if (/Adjusted AUROC/) {
			adj_auroc = $NF;
		} else if (/measures AUPRC/) {
			auprc = $NF;
		} else if (/Adjusted AUPRC/) {
			adj_auprc = $NF;
		} else if (/measures AUPRGC/) {
			auprgc = $NF;
		} else if (/Adjusted AUPRGC/) {
			adj_auprgc = $NF;
		} else if (/measures Average Precision/) {
			avg_prec = $NF;
		} else if (/Adjusted AveP/) {
			adj_avg_prec = $NF;
		} else if (/measures R-Precision/) {
			rprec = $NF;
		} else if (/Adjusted R-Prec/) {
			adj_rprec = $NF;
		} else if (/measures Maximum F1/) {
			max_f1 = $NF;
		} else if (/Adjusted Max F1/) {
			adj_max_f1 = $NF;
		} else if (/measures DCG/) {
			dcg = $NF;
		} else if (/Adjusted DCG/) {
			adj_dcg = $NF;
		} else if (/measures NDCG/) {
			ndcg = $NF;
		} else if (/runtime: /) {
			runtime = $(NF-1);
		}
	} END {
		print dataset","dbscan_epsilon","dbscan_minpts","gdbscan_coremodel","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
	}' $algorithm-$dataset.out >> $csvFile
	rm $algorithm-$dataset.out	
}

process_dataset_10versions() {
	local dataset="$1"
    local labelColumn=$2
	local epsilon=$3
	local minpts=$4

	for i in {1..10}; do
		$javaCommand -algorithm $algorithm \
			-time \
			-dbc.in datasets/real/$dataset\_withoutdupl\_norm\_v$i.arff \
			-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
			-dbscan.epsilon $epsilon \
			-gdbscan.core-model true \
			-dbscan.minpts $minpts > $algorithm-$dataset\_$i.out
		awk -v dataset=$dataset '/dbscan.epsilon|dbscan.minpts|gdbscan.core-model|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
			if (/dbscan.epsilon/) {
				dbscan_epsilon = $NF;  # assuming the value is in the last field
			} else if (/dbscan.minpts/) {
				dbscan_minpts = $NF;
			} else if (/gdbscan.core-model/) {
				gdbscan_coremodel = $NF;
			} else if (/measures AUROC/) {
				auroc = $NF;
			} else if (/Adjusted AUROC/) {
				adj_auroc = $NF;
			} else if (/measures AUPRC/) {
				auprc = $NF;
			} else if (/Adjusted AUPRC/) {
				adj_auprc = $NF;
			} else if (/measures AUPRGC/) {
				auprgc = $NF;
			} else if (/Adjusted AUPRGC/) {
				adj_auprgc = $NF;
			} else if (/measures Average Precision/) {
				avg_prec = $NF;
			} else if (/Adjusted AveP/) {
				adj_avg_prec = $NF;
			} else if (/measures R-Precision/) {
				rprec = $NF;
			} else if (/Adjusted R-Prec/) {
				adj_rprec = $NF;
			} else if (/measures Maximum F1/) {
				max_f1 = $NF;
			} else if (/Adjusted Max F1/) {
				adj_max_f1 = $NF;
			} else if (/measures DCG/) {
				dcg = $NF;
			} else if (/Adjusted DCG/) {
				adj_dcg = $NF;
			} else if (/measures NDCG/) {
				ndcg = $NF;
			} else if (/runtime: /) {
				runtime = $(NF-1);
			}
		} END {
			print dataset","dbscan_epsilon","dbscan_minpts","gdbscan_coremodel","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
		}' $algorithm-$dataset\_$i.out >> $csvFile
	
		rm $algorithm-$dataset\_$i.out
	done
}

process_dataset_10versions_5perc() {
	local dataset="$1"
    local labelColumn=$2
	local epsilon=$3
	local minpts=$4

	for i in {1..10}; do
		$javaCommand -algorithm $algorithm \
			-time \
			-dbc.in datasets/real/$dataset\_withoutdupl\_norm\_05\_v$i.arff \
			-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
			-dbscan.epsilon $epsilon \
			-gdbscan.core-model true \
			-dbscan.minpts $minpts > $algorithm-$dataset\_$i.out
		awk -v dataset=$dataset '/dbscan.epsilon|dbscan.minpts|gdbscan.core-model|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
			if (/dbscan.epsilon/) {
				dbscan_epsilon = $NF;  # assuming the value is in the last field
			} else if (/dbscan.minpts/) {
				dbscan_minpts = $NF;
			} else if (/gdbscan.core-model/) {
				gdbscan_coremodel = $NF;
			} else if (/measures AUROC/) {
				auroc = $NF;
			} else if (/Adjusted AUROC/) {
				adj_auroc = $NF;
			} else if (/measures AUPRC/) {
				auprc = $NF;
			} else if (/Adjusted AUPRC/) {
				adj_auprc = $NF;
			} else if (/measures AUPRGC/) {
				auprgc = $NF;
			} else if (/Adjusted AUPRGC/) {
				adj_auprgc = $NF;
			} else if (/measures Average Precision/) {
				avg_prec = $NF;
			} else if (/Adjusted AveP/) {
				adj_avg_prec = $NF;
			} else if (/measures R-Precision/) {
				rprec = $NF;
			} else if (/Adjusted R-Prec/) {
				adj_rprec = $NF;
			} else if (/measures Maximum F1/) {
				max_f1 = $NF;
			} else if (/Adjusted Max F1/) {
				adj_max_f1 = $NF;
			} else if (/measures DCG/) {
				dcg = $NF;
			} else if (/Adjusted DCG/) {
				adj_dcg = $NF;
			} else if (/measures NDCG/) {
				ndcg = $NF;
			} else if (/runtime: /) {
				runtime = $(NF-1);
			}
		} END {
			print dataset","dbscan_epsilon","dbscan_minpts","gdbscan_coremodel","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
		}' $algorithm-$dataset\_$i.out >> $csvFile
	
		rm $algorithm-$dataset\_$i.out
	done
}

case "$1" in
    -l) _literature ;;
    -s) _semantic ;;
    *)  echo "Usage: ./dbscanod.sh [-l | -s]" ;;
esac