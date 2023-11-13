#!/bin/bash
_2d() {
	local labelColumn=2
    local evaluator="Scalability"

	local datasets_2=("2clusters-noise-2d-1.56perc" "2clusters-noise-2d-3.13perc" "2clusters-noise-2d-6.25perc" \
        "2clusters-noise-2d-12.5perc")
	for dataset in "${datasets_2[@]}"; do
    	process_dataset "$dataset" "$labelColumn" "$evaluator"
	done

	local datasets_5=("5clusters-noise-2d-1.56perc" "5clusters-noise-2d-3.13perc" "5clusters-noise-2d-6.25perc" \
        "5clusters-noise-2d-12.5perc")
	for dataset in "${datasets_5[@]}"; do
    	process_dataset "$dataset" "$labelColumn" "$evaluator"
	done

	local datasets_10=("10clusters-noise-2d-1.56perc" "10clusters-noise-2d-3.13perc" "10clusters-noise-2d-6.25perc" \
        "10clusters-noise-2d-12.5perc")
    for dataset in "${datasets_10[@]}"; do
    	process_dataset "$dataset" "$labelColumn" "$evaluator"
	done
}

_10d() {
	local labelColumn=10
    local evaluator="Scalability"

	local datasets_2=("2clusters-noise-10d-1.56perc" "2clusters-noise-10d-3.13perc" "2clusters-noise-10d-6.25perc" \
        "2clusters-noise-10d-12.5perc")
	for dataset in "${datasets_2[@]}"; do
    	process_dataset "$dataset" "$labelColumn" "$evaluator"
	done

	local datasets_5=("5clusters-noise-10d-1.56perc" "5clusters-noise-10d-3.13perc" "5clusters-noise-10d-6.25perc" \
        "5clusters-noise-10d-12.5perc")
	for dataset in "${datasets_5[@]}"; do
    	process_dataset "$dataset" "$labelColumn" "$evaluator"
	done

	local datasets_10=("10clusters-noise-10d-1.56perc" "10clusters-noise-10d-3.13perc" "10clusters-noise-10d-6.25perc" \
        "10clusters-noise-10d-12.5perc")
    for dataset in "${datasets_10[@]}"; do
    	process_dataset "$dataset" "$labelColumn" "$evaluator"
	done
}

#$((1 + RANDOM % 2147483647))
javaCommand="java -Xmx10G -jar algorithms/binaries/elki-kmeans--star.jar KDDCLIApplication"
algorithm="outlier.clustering.KMeansMinusMinusOutlierDetectionStar"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

process_dataset() {
    local dataset="$1"
    local labelColumn=$2
    local evaluator="$3"

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,l,runtime" >> "$csvFile"

	for k in {1..50}; do
		local list=(25 50 75 100 150 200 250 300)
		
		for l in "${list[@]}"; do
			local l=`echo "scale=4; $l / 10000" | bc -l`

			for _ in {1..10}; do
				$javaCommand -algorithm $algorithm \
					-time \
					-dbc.in datasets/synthetic/scalability/$dataset\.csv \
					-parser.labelIndices $labelColumn \
					-kmeans.seed $((1 + RANDOM % 2147483647)) \
					-kmeans.k $k \
					-kmeans.maxiter 100 \
					-algorithm.distancefunction minkowski.EuclideanDistance \
					-kmeansmm.l $l \
					-kmeansmm.noisecluster true > $algorithm-$dataset.out
				awk '/kmeans.k|kmeansmm.l|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
					if (/kmeans.k/) {
						kmeans_k = $NF;  # assuming the value is in the last field
					} else if (/kmeansmm.l/) {
						kmeansmm_l = $NF;
					} else if (/runtime: /) {
						runtime = $(NF-1);
					}
				} END {
					print kmeans_k","kmeansmm_l","runtime;
				}' $algorithm-$dataset.out >> $csvFile
			done
		done
	done

	rm $algorithm-$dataset.out
}

case "$1" in
    -2) _2d ;;
    -10) _10d ;;
    *)  echo "Usage: ./kmeans--star.sh [-2 | -10]" ;;
esac