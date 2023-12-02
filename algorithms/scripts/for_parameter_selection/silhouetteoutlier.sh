#!/bin/bash

#$((1 + RANDOM % 2147483647))
javaCommand="java -Xmx30G -jar algorithms/binaries/elki-0.8.0.jar KDDCLIApplication"
algorithm="outlier.clustering.SilhouetteOutlierDetection"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

evaluator="Adaptive"
csvFile="$results/$algorithm/$evaluator/result.csv"
[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
# echo "# $(date) - $evaluator" >> "$csvFile"
echo "dataset,k,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

############ 11 datasets used in the literature ############
_literature() {
	dataset="ALOI"
	labelColumn=27
	k=3
	process_dataset "$dataset" "$labelColumn" "$k"
	
	dataset="Glass"
	labelColumn=7
	k=2
	process_dataset "$dataset" "$labelColumn" "$k"

	dataset="Ionosphere"
	labelColumn=32
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="KDDCup99"
	labelColumn=38
	k=5
	process_dataset "$dataset" "$labelColumn" "$k"

	dataset="Lymphography"
	labelColumn=3
	k=49
	process_dataset "$dataset" "$labelColumn" "$k"

	dataset="PenDigits"
	labelColumn=16
	k=6
	process_dataset_10versions "$dataset" "$labelColumn" "$k"

	dataset="Shuttle"
	labelColumn=9
	k=2
	process_dataset_10versions "$dataset" "$labelColumn" "$k"

	dataset="Waveform"
	labelColumn=21
	k=2
	process_dataset_10versions "$dataset" "$labelColumn" "$k"

	dataset="WBC"
	labelColumn=9
	k=2
	process_dataset_10versions "$dataset" "$labelColumn" "$k"

	dataset="WDBC"
	labelColumn=30
	k=2
	process_dataset_10versions "$dataset" "$labelColumn" "$k"

	dataset="WPBC"
	labelColumn=33
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"
}

# ############ 12 datasets semantically meaningful ############
_semantic() {
	dataset="Annthyroid"
	labelColumn=21
	k=4
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Arrhythmia"
	labelColumn=259
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Cardiotocography"
	labelColumn=21
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="HeartDisease"
	labelColumn=13
	k=9
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Hepatitis"
	labelColumn=19
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="InternetAds"
	labelColumn=1555
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="PageBlocks"
	labelColumn=10
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Parkinson"
	labelColumn=22
	k=3
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Pima"
	labelColumn=8
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="SpamBase"
	labelColumn=57
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Stamps"
	labelColumn=9
	k=2
	process_dataset_10versions_5perc "$dataset" "$labelColumn" "$k"

	dataset="Wilt"
	labelColumn=5
	k=3
	process_dataset_5perc "$dataset" "$labelColumn" "$k"
}

process_dataset() {
	local dataset="$1"
    local labelColumn=$2
	local k=$3

	for _ in {1..10}; do
		$javaCommand -algorithm $algorithm \
			-time \
			-dbc.in datasets/real/$dataset\_withoutdupl\_norm.arff \
			-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
			-kmeans.seed $((1 + RANDOM % 2147483647)) \
			-kmeans.k $k \
			-kmeans.maxiter 100 \
			-algorithm.distancefunction minkowski.EuclideanDistance \
			-silhouette.clustering kmeans.HamerlyKMeans > $algorithm-$dataset.out
		awk -v dataset=$dataset '/runtime: |kmeans.k|measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
			if (/kmeans.k/) {
				kmeans_k = $NF;  # assuming the value is in the last field
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
			print dataset","kmeans_k","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
		}' $algorithm-$dataset.out >> $csvFile
	done
	rm $algorithm-$dataset.out
}

process_dataset_5perc() {
	local dataset="$1"
    local labelColumn=$2
	local k=$3

	for _ in {1..10}; do
		$javaCommand -algorithm $algorithm \
			-time \
			-dbc.in datasets/real/$dataset\_withoutdupl\_norm\_05.arff \
			-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
			-kmeans.seed $((1 + RANDOM % 2147483647)) \
			-kmeans.k $k \
			-kmeans.maxiter 100 \
			-algorithm.distancefunction minkowski.EuclideanDistance \
			-silhouette.clustering kmeans.HamerlyKMeans > $algorithm-$dataset.out
		awk -v dataset=$dataset '/runtime: |kmeans.k|measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
			if (/kmeans.k/) {
				kmeans_k = $NF;  # assuming the value is in the last field
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
			print dataset","kmeans_k","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
		}' $algorithm-$dataset.out >> $csvFile
	done
	rm $algorithm-$dataset.out

}

process_dataset_10versions() {
	local dataset="$1"
    local labelColumn=$2
	local k=$3

	for i in {1..10}; do
		for _ in {1..10}; do
			$javaCommand -algorithm $algorithm \
				-time \
				-dbc.in datasets/real/$dataset\_withoutdupl\_norm\_v$i.arff \
				-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
				-kmeans.seed $((1 + RANDOM % 2147483647)) \
				-kmeans.k $k \
				-kmeans.maxiter 100 \
				-algorithm.distancefunction minkowski.EuclideanDistance \
				-silhouette.clustering kmeans.HamerlyKMeans > $algorithm-$dataset\_$i.out
			awk -v dataset=$dataset '/runtime: |kmeans.k|measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/kmeans.k/) {
					kmeans_k = $NF;  # assuming the value is in the last field
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
				print dataset","kmeans_k","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
			}' $algorithm-$dataset\_$i.out >> $csvFile
		done
		
		rm $algorithm-$dataset\_$i.out
	done
}

process_dataset_10versions_5perc() {
	local dataset="$1"
    local labelColumn=$2
	local k=$3

	for i in {1..10}; do
		for _ in {1..10}; do
			$javaCommand -algorithm $algorithm \
				-time \
				-dbc.in datasets/real/$dataset\_withoutdupl\_norm\_05\_v$i.arff \
				-dbc.parser ArffParser -arff.externalid "(id)" -arff.classlabel "(outlier)" \
				-kmeans.seed $((1 + RANDOM % 2147483647)) \
				-kmeans.k $k \
				-kmeans.maxiter 100 \
				-algorithm.distancefunction minkowski.EuclideanDistance \
				-silhouette.clustering kmeans.HamerlyKMeans > $algorithm-$dataset\_$i.out
			awk -v dataset=$dataset '/runtime: |kmeans.k|measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/kmeans.k/) {
					kmeans_k = $NF;  # assuming the value is in the last field
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
				print dataset","kmeans_k","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
			}' $algorithm-$dataset\_$i.out >> $csvFile
		done
		
		rm $algorithm-$dataset\_$i.out
	done
}

case "$1" in
    -l) _literature ;;
    -s) _semantic ;;
    *)  echo "Usage: ./silhouetteoutlier.sh [-l | -s]" ;;
esac