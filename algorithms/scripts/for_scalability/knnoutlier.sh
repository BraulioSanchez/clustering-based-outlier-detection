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
javaCommand="java -Xmx10G -jar algorithms/binaries/elki-0.8.0.jar KDDCLIApplication"
algorithm="outlier.distance.KNNOutlier"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

process_dataset() {
    local dataset="$1"
    local labelColumn=$2
    local evaluator="$3"

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "k,runtime" >> "$csvFile"

	local ks=(1 500 1000 1500 2000 2500 3000 3500 4000 4500 5000)
	for k in "${ks[@]}"; do
		for _ in {1..10}; do
			$javaCommand -algorithm $algorithm \
				-time \
				-dbc.in datasets/synthetic/scalability/$dataset\.csv \
				-parser.labelIndices $labelColumn \
				-knno.k $k \
				-algorithm.distancefunction minkowski.EuclideanDistance > $algorithm-$dataset.out
			awk '/knno.k|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/knno.k/) {
					knno_k = $NF;  # assuming the value is in the last field
				} else if (/runtime: /) {
					runtime = $(NF-1);
				}
			} END {
				print knno_k","runtime;
			}' $algorithm-$dataset.out >> $csvFile
		done
	done

	rm $algorithm-$dataset.out
}

case "$1" in
    -2) _2d ;;
    -10) _10d ;;
    *)  echo "Usage: ./knnoutlier.sh [-2 | -10]" ;;
esac