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
javaCommand="java -Xmx10G -jar algorithms/binaries/elki-iforest.jar KDDCLIApplication"
algorithm="outlier.density.IsolationForest"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

process_dataset() {
    local dataset="$1"
    local labelColumn=$2
    local evaluator="$3"

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "numtrees,subsample,runtime" >> "$csvFile"

	for psi in 2 4 8 16 32 64 128 256 512 1024; do
		for _ in {1..10}; do
			$javaCommand -algorithm $algorithm \
				-time \
				-dbc.in datasets/synthetic/scalability/$dataset\.csv \
				-parser.labelIndices $labelColumn \
				-iforest.seed $((1 + RANDOM % 2147483647)) \
				-iforest.numtrees 100 \
				-iforest.subsample $psi > $algorithm-$dataset.out
			awk '/iforest.numtrees|iforest.subsample|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
				if (/iforest.numtrees/) {
					iforest_numtrees = $NF;  # assuming the value is in the last field
				} else if (/iforest.subsample/) {
					iforest_subsample = $NF;
				} else if (/runtime: /) {
					runtime = $(NF-1);
				}
			} END {
				print iforest_numtrees","iforest_subsample","runtime;
			}' $algorithm-$dataset.out >> $csvFile
		done
	done

	rm $algorithm-$dataset.out
}

case "$1" in
    -2) _2d ;;
    -10) _10d ;;
    *)  echo "Usage: ./iforest.sh [-2 | -10]" ;;
esac

# datasets=("2clusters-noise-2d-1.56perc" "2clusters-noise-2d-3.13perc" \
# 		"2clusters-noise-2d-6.25perc" "2clusters-noise-2d-12.5perc")
# labelColumn=2
# evaluators=("Scalability")
# for evaluator in "${evaluators[@]}"
# do
# 	[ -d $results/$algorithm/$evaluator ] || mkdir -p $results/$algorithm/$evaluator

# 	for DATASET in "${datasets[@]}"
# 	do
# 		echo "# $(date) - $evaluator" >> $results/$algorithm/$evaluator/$DATASET.log

# 		for psi in 2 4 8 16 32 64 128 256 512 1024; do
# 			for _ in {1..10}; do
# 				$javaCommand -algorithm $algorithm \
# 				-time \
# 				-dbc.in datasets/synthetic/scalability/$DATASET\.csv \
# 				-parser.labelIndices $labelColumn \
# 				-iforest.seed $((1 + RANDOM % 2147483647)) \
# 				-iforest.numtrees 100 \
# 				-iforest.subsample $psi > $algorithm-$DATASET.out
# 				awk '/-iforest.numtrees|-iforest.subsample|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{print $0}' $algorithm-$DATASET.out >> $results/$algorithm/$evaluator/$DATASET.log
# 			done
# 		done

# 		rm $algorithm-$DATASET.out
# 	done
# done
