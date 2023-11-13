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
javaCommand="java -Xmx10G -jar algorithms/binaries/elki-outrank_h.jar KDDCLIApplication"
algorithm="outlier.subspace.OutRankS1HDBSCAN"
alias="outlier.subspace.OutRank_H"

results="$(pwd)/results"
[ -d $results/$alias ] || mkdir -p $results/$alias

process_dataset() {
    local dataset="$1"
    local labelColumn=$2
    local evaluator="$3"

	local csvFile="$results/$alias/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "minpts,minclsize,alpha,subspaces,runtime" >> "$csvFile"

	local list=(125 250 500 1000 2000 3000 4000 5000 10000)
	for j in "${list[@]}"; do
		minpts=$((2 * $labelColumn - 1))
		minpts=$(($minpts * $j / 1000))

		for _ in {1..10}; do
			$javaCommand -algorithm $algorithm \
				-time \
				-dbc.in datasets/synthetic/scalability/$dataset\.csv \
				-parser.labelIndices $labelColumn \
				-outrank.s1.seed $((1 + RANDOM % 2147483647)) \
				-outrank.s1.alpha 0.25 \
				-outrank.s1.subspaces 100 \
				-algorithm HDBSCANLinearMemory \
				-algorithm.distancefunction minkowski.EuclideanDistance \
				-hdbscan.minPts $minpts \
				-hdbscan.minclsize $minpts > $algorithm-$dataset.out
			awk '/hdbscan.minPts|hdbscan.minclsize|outrank.s1.alpha|outrank.s1.subspaces|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/hdbscan.minPts/) {
					hdbscan_minPts = $NF;  # assuming the value is in the last field
				} else if(/hdbscan.minclsize/) {
					hdbscan_minclsize = $NF;
				} else if(/outrank.s1.alpha/) {
					outrank_s1_alpha = $NF;
				} else if (/outrank.s1.subspaces/) {
					outrank_s1_subspaces = $NF;
				} else if (/runtime: /) {
					runtime = $(NF-1);
				}
			} END {
				print hdbscan_minPts","hdbscan_minclsize","outrank_s1_alpha","outrank_s1_subspaces","runtime;
			}' $algorithm-$dataset.out >> $csvFile
		done
	done

	rm $algorithm-$dataset.out
}

case "$1" in
    -2) _2d ;;
    -10) _10d ;;
    *)  echo "Usage: ./outrank_h.sh [-2 | -10]" ;;
esac