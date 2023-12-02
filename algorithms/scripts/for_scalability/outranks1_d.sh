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
algorithm="outlier.subspace.OutRankS1"
alias="outlier.subspace.OutRank_D"

results="$(pwd)/results"
[ -d $results/$alias ] || mkdir -p $results/$alias

process_dataset() {
    local dataset="$1"
    local labelColumn=$2
    local evaluator="$3"

	local csvFile="$results/$alias/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "epsilon,mu,alpha,runtime" >> "$csvFile"

	for mu in {1..50}; do
		for epsilon in 0.001 0.01; do
			for _ in {1..10}; do
				$javaCommand -algorithm $algorithm \
					-time \
					-dbc.in datasets/synthetic/scalability/$dataset\.csv \
					-parser.labelIndices $labelColumn \
					-outrank.s1.alpha 0.25 \
					-outrank.algorithm DiSH \
					-dish.mu $mu \
					-dish.epsilon $epsilon > $algorithm-$dataset.out
				awk '/dish.mu|dish.epsilon|outrank.s1.alpha|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
					if (/dish.mu/) {
						dish_mu = $NF;  # assuming the value is in the last field
					} else if(/dish.epsilon/) {
						dish_epsilon = $NF;
					} else if(/outrank.s1.alpha/) {
						outrank_s1_alpha = $NF;
					} else if (/runtime: /) {
						runtime = $(NF-1);
					}
				} END {
					print dish_epsilon","dish_mu","outrank_s1_alpha","runtime;
				}' $algorithm-$dataset.out >> $csvFile
			done
		done
	done

	rm $algorithm-$dataset.out
}

case "$1" in
    -2) _2d ;;
    -10) _10d ;;
    *)  echo "Usage: ./outrank_d.sh [-2 | -10]" ;;
esac