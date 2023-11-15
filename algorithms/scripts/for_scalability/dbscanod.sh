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
javaCommand="java -Xmx10G -jar algorithms/binaries/elki.jar KDDCLIApplication"
algorithm="outlier.clustering.DBSCANOutlierDetection"

results="$(pwd)/results"
[ -d $results/$algorithm ] || mkdir -p $results/$algorithm

process_dataset() {
    local dataset="$1"
    local labelColumn=$2
    local evaluator="$3"

	local csvFile="$results/$algorithm/$evaluator/$dataset.csv"
	[ -d "$(dirname "$csvFile")" ] || mkdir -p "$(dirname "$csvFile")"
	# echo "# $(date) - $evaluator" >> "$csvFile"
	echo "epsilon,minpts,core,runtime" >> "$csvFile"

	local diagonal=`echo "scale=12; sqrt($labelColumn)" | bc -l`
	local step=`echo "scale=12; (($diagonal * .2) - ($diagonal * .01)) / 50" | bc -l`
	for ii in {0..50}; do
		epsilon=`echo "scale=12; ($diagonal * .01) + ($ii * $step)" | bc -l`
		list=(125 250 500 1000 2000 3000 4000 5000 10000)
		for j in "${list[@]}"; do
			minpts=$((2 * $labelColumn - 1))
			minpts=$(($minpts * $j / 1000))

			coreModels=(true)
			for coreModel in "${coreModels[@]}"; do
				for _ in {1..10}; do
					$javaCommand -algorithm $algorithm \
						-time \
						-dbc.in datasets/synthetic/scalability/$dataset\.csv \
						-parser.labelIndices $labelColumn \
						-dbscan.epsilon $epsilon \
						-gdbscan.core-model $coreModel \
						-dbscan.minpts $minpts > $algorithm-$dataset.out
					awk '/dbscan.epsilon|dbscan.minpts|gdbscan.core-model|runtime: |measures AUROC|Adjusted AUROC|measures AUPRC|Adjusted AUPRC|measures AUPRGC|Adjusted AUPRGC|measures Average Precision|Adjusted AveP|measures R-Precision|Adjusted R-Prec|measures Maximum F1|Adjusted Max F1|measures DCG|Adjusted DCG|measures NDCG /{
						if (/dbscan.epsilon/) {
							dbscan_epsilon = $NF;  # assuming the value is in the last field
						} else if (/dbscan.minpts/) {
							dbscan_minpts = $NF;
						} else if (/gdbscan.core-model/) {
							gdbscan_coremodel = $NF;
						} else if (/runtime: /) {
							runtime = $(NF-1);
						}
					} END {
						print dbscan_epsilon","dbscan_minpts","gdbscan_coremodel","runtime;
					}' $algorithm-$dataset.out >> $csvFile
				done
			done
		done
	done	

	rm $algorithm-$dataset.out
}

case "$1" in
    -2) _2d ;;
    -10) _10d ;;
    *)  echo "Usage: ./dbscanod.sh [-2 | -10]" ;;
esac
