#!/bin/bash

#$((1 + RANDOM % 2147483647))
javaCommand="java -Xmx10G -jar algorithms/binaries/elki-silhouetteoutlier.jar KDDCLIApplication"
algorithm="outlier.clustering.SilhouetteOutlierDetection"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

evaluator="Accuracy"

############ 11 datasets used in the literature ############
_literature() {
	dataset="ALOI"
	labelColumn=27
	process_dataset "$dataset" "$labelColumn"
	
	dataset="Glass"
	labelColumn=7
	process_dataset "$dataset" "$labelColumn"

	dataset="Ionosphere"
	labelColumn=32
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="KDDCup99"
	labelColumn=38
	process_dataset "$dataset" "$labelColumn"

	dataset="Lymphography"
	labelColumn=3
	process_dataset "$dataset" "$labelColumn"

	dataset="PenDigits"
	labelColumn=16
	process_dataset_10versions "$dataset" "$labelColumn"

	dataset="Shuttle"
	labelColumn=9
	process_dataset_10versions "$dataset" "$labelColumn"

	dataset="Waveform"
	labelColumn=21
	process_dataset_10versions "$dataset" "$labelColumn"

	dataset="WBC"
	labelColumn=9
	process_dataset_10versions "$dataset" "$labelColumn"

	dataset="WDBC"
	labelColumn=30
	process_dataset_10versions "$dataset" "$labelColumn"

	dataset="WPBC"
	labelColumn=33
	process_dataset_10versions_5perc "$dataset" "$labelColumn"
}

# ############ 12 datasets semantically meaningful ############
_semantic() {
	dataset="Annthyroid"
	labelColumn=21
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Arrhythmia"
	labelColumn=259
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Cardiotocography"
	labelColumn=21
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="HeartDisease"
	labelColumn=13
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Hepatitis"
	labelColumn=19
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="InternetAds"
	labelColumn=1555
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="PageBlocks"
	labelColumn=10
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Parkinson"
	labelColumn=22
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Pima"
	labelColumn=8
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="SpamBase"
	labelColumn=57
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Stamps"
	labelColumn=9
	process_dataset_10versions_5perc "$dataset" "$labelColumn"

	dataset="Wilt"
	labelColumn=5
	process_dataset_5perc "$dataset" "$labelColumn"
}

############ 16 Synthetic datasets ############
_synthetic() {
	datasets=("10clusters-10k-2d-random-gaussian-5%global" "5clusters-10k-2d-random-gaussian-5%global" \
		"2clusters-10k-2d-random-gaussian-5%global" "5clusters-10k-2d-random-gaussian-5%local" \
		"5clusters-10k-2d-random-gaussian-5%microcluster" \
		"5clusters-10k-2d-random-uniform-5%global" \
		"5clusters-10k-2d-sine-gaussian-5%global" \
		"5clusters-10k-2d-grid-gaussian-5%global" "5clusters-1k-2d-random-gaussian-5%global" \
		"5clusters-10k-2d-random-gaussian-10%global" "5clusters-50k-2d-random-gaussian-5%global" \
		"5clusters-10k-2d-random-gaussian-1%global")
	labelColumn=2
	for dataset in "${datasets[@]}"; do
		process_synhtetic_dataset "$dataset" "$labelColumn"
	done

	dataset="5clusters-10k-10d-random-gaussian-5%global"
	labelColumn=10
	process_synhtetic_dataset "$dataset" "$labelColumn"

	dataset="5clusters-10k-12d2irr-random-gaussian-5%global"
	labelColumn=12
	process_synhtetic_dataset "$dataset" "$labelColumn"

	dataset="5clusters-10k-15d5irr-random-gaussian-5%global"
	labelColumn=15
	process_synhtetic_dataset "$dataset" "$labelColumn"

	dataset="5clusters-10k-20d10irr-random-gaussian-5%global"
	labelColumn=20
	process_synhtetic_dataset "$dataset" "$labelColumn"
}

process_synhtetic_dataset() {
	local dataset="$1"
    local labelColumn=$2

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,clustering,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

	for k in {1..50}; do
		for _ in {1..10}; do
			for i in {1..5}; do
				$javaCommand -algorithm $algorithm \
					-time \
					-dbc.in datasets/synthetic/quality/$dataset-v$i\.csv \
					-parser.labelIndices $labelColumn \
					-kmeans.seed $((1 + RANDOM % 2147483647)) \
					-kmeans.k $k \
					-kmeans.maxiter 100 \
					-algorithm.distancefunction minkowski.EuclideanDistance \
					-silhouette.clustering kmeans.HamerlyKMeans > $algorithm-$dataset\_$i.out
				awk '/kmeans.k|silhouette.clustering|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
					if (/kmeans.k/) {
						kmeans_k = $NF;  # assuming the value is in the last field
					} else if (/silhouette.clustering/) {
						silhouette_clustering = $NF;
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
					print kmeans_k","silhouette_clustering","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
				}' $algorithm-$dataset\_$i.out >> $csvFile
				
				rm $algorithm-$dataset\_$i.out
			done
		done
	done
}

process_dataset() {
	local dataset="$1"
    local labelColumn=$2

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,clustering,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

	for k in {1..50}; do
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
			awk '/kmeans.k|silhouette.clustering|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/kmeans.k/) {
					kmeans_k = $NF;  # assuming the value is in the last field
				} else if (/silhouette.clustering/) {
					silhouette_clustering = $NF;
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
				print kmeans_k","silhouette_clustering","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
			}' $algorithm-$dataset.out >> $csvFile
			
			rm $algorithm-$dataset.out
		done
	done
}

process_dataset_5perc() {
	local dataset="$1"
    local labelColumn=$2

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,clustering,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

	for k in {1..50}; do
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
			awk '/kmeans.k|silhouette.clustering|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/kmeans.k/) {
					kmeans_k = $NF;  # assuming the value is in the last field
				} else if (/silhouette.clustering/) {
					silhouette_clustering = $NF;
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
				print kmeans_k","silhouette_clustering","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
			}' $algorithm-$dataset.out >> $csvFile
			
			rm $algorithm-$dataset.out
		done
	done
}

process_dataset_10versions() {
	local dataset="$1"
    local labelColumn=$2

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,clustering,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

	for k in {1..50}; do
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
				awk '/kmeans.k|silhouette.clustering|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
					if (/kmeans.k/) {
						kmeans_k = $NF;  # assuming the value is in the last field
					} else if (/silhouette.clustering/) {
						silhouette_clustering = $NF;
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
					print kmeans_k","silhouette_clustering","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
				}' $algorithm-$dataset\_$i.out >> $csvFile
				
				rm $algorithm-$dataset\_$i.out
			done
		done
	done
}

process_dataset_10versions_5perc() {
	local dataset="$1"
    local labelColumn=$2

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,clustering,auroc,auprc,auprgc,avgprec,rprec,f1,dcg,ndcg,adj-auroc,adj-auprc,adj-auprgc,adj-avgprec,adj-rprec,adj-f1,adj-dcg,runtime" >> "$csvFile"

	for k in {1..50}; do
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
				awk '/kmeans.k|silhouette.clustering|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
					if (/kmeans.k/) {
						kmeans_k = $NF;  # assuming the value is in the last field
					} else if (/silhouette.clustering/) {
						silhouette_clustering = $NF;
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
					print kmeans_k","silhouette_clustering","auroc","auprc","auprgc","avg_prec","rprec","max_f1","dcg","ndcg","adj_auroc","adj_auprc","adj_auprgc","adj_avg_prec","adj_rprec","adj_max_f1","adj_dcg","runtime;
				}' $algorithm-$dataset\_$i.out >> $csvFile
				
				rm $algorithm-$dataset\_$i.out
			done
		done
	done
}

case "$1" in
    -l) _literature ;;
    -s) _semantic ;;
	-syn) _synthetic ;;
    *)  echo "Usage: ./silhouetteoutlier.sh [-l | -s | -syn]" ;;
esac