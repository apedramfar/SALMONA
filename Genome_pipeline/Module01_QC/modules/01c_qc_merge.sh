#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

source package $PKG_MULTIQC
source package $PKG_METAPHLAN

echo "Job started"; hostname; date

# ── Directories ───────────────────────────────────────────────────────────────
FASTQC_DIR="$OUT_DIR/01_qc/fastqc"
HOST_DIR="$OUT_DIR/01_qc/host_removal"
MET_DIR="$OUT_DIR/01_qc/metaphlan"
AGG_DIR="$OUT_DIR/01_qc/aggregated"
MULTIQC_DIR="$AGG_DIR/multiqc"

[[ ! -d "$MULTIQC_DIR" ]] && mkdir -p "$MULTIQC_DIR"


# ── MultiQC ───────────────────────────────────────────────────────────────────
echo "Running MultiQC..."
FASTQC_COUNT=$(find "$FASTQC_DIR" -name "*_fastqc.zip" | wc -l)
if [[ "$FASTQC_COUNT" -eq 0 ]]; then
    echo "ERROR: No FastQC zip files found in $FASTQC_DIR"
    exit 1
fi
echo "Found $FASTQC_COUNT FastQC zip files"

multiqc "$FASTQC_DIR" \
    --outdir "$MULTIQC_DIR" \
    --filename multiqc_report \
    --force
echo "MultiQC complete"

# ── Parse Hostile JSON files ──────────────────────────────────────────────────
echo "Parsing Hostile JSON files..."
JSON_COUNT=$(find "$HOST_DIR" -name "*_hostmap.json" | wc -l)
if [[ "$JSON_COUNT" -eq 0 ]]; then
    echo "ERROR: No Hostile JSON files found in $HOST_DIR"
    exit 1
fi
echo "Found $JSON_COUNT Hostile JSON files"

HOSTILE_CSV="$AGG_DIR/hostile_summary.csv"
echo "sample_name,reads_in,reads_out,reads_removed,reads_removed_proportion,aligner,database" > "$HOSTILE_CSV"

for json_file in "$HOST_DIR"/*_hostmap.json; do
    if [[ -f "$json_file" ]]; then
        sample_name=$(basename "$json_file" _hostmap.json)
        reads_in=$(jq -r '.[0].reads_in' "$json_file")
        reads_out=$(jq -r '.[0].reads_out' "$json_file")
        reads_removed=$(jq -r '.[0].reads_removed' "$json_file")
        reads_removed_proportion=$(jq -r '.[0].reads_removed_proportion' "$json_file")
        aligner=$(jq -r '.[0].aligner' "$json_file")
        database=$(jq -r '.[0].index' "$json_file")
        echo "$sample_name,$reads_in,$reads_out,$reads_removed,$reads_removed_proportion,$aligner,$database" >> "$HOSTILE_CSV"
    fi
done
echo "Hostile summary written to $HOSTILE_CSV"

# ── Parse MetaPhlAn profiles: contamination summary ──────────────────────────
echo "Parsing MetaPhlAn profiles..."
PROFILE_COUNT=$(find "$MET_DIR" -name "*.unclprofile.txt" | wc -l)
if [[ "$PROFILE_COUNT" -eq 0 ]]; then
    echo "ERROR: No .unclprofile.txt files found in $MET_DIR"
    exit 1
fi
echo "Found $PROFILE_COUNT MetaPhlAn profiles"

CONTAM_TSV="$AGG_DIR/contamination_summary.tsv"
echo -e "sample_id\tspecies_count\ttop_species\ttop_species_abundance\tunclassified_pct\tstatus" > "$CONTAM_TSV"

for profile in "$MET_DIR"/*.unclprofile.txt; do
    sample_id=$(basename "$profile" .unclprofile.txt)

    # Extract unclassified percentage (UNKNOWN row)
    unclassified=$(grep "^UNKNOWN" "$profile" | awk '{print $2}')
    if [[ -z "$unclassified" ]]; then
        unclassified=0
    fi

    # Extract species-level lines (contains |s__ but not |t__)
    species_lines=$(grep "|s__" "$profile" | grep -v "|t__")
    species_count=$(echo "$species_lines" | grep -c "s__" || true)

    # Extract top species name and abundance
    top_species_line=$(echo "$species_lines" | sort -t$'\t' -k2 -rn | head -1)
    top_species=$(echo "$top_species_line" | awk -F'\t' '{print $1}' | sed 's/.*|s__//' | sed 's/|.*//')
    top_abundance=$(echo "$top_species_line" | awk -F'\t' '{print $2}')

    if [[ -z "$top_species" ]]; then
        top_species="none"
        top_abundance=0
    fi

    # ── Evaluate contamination status ─────────────────────────────────────────
    STATUS="OK"
    WARNINGS=()

    if (( $(echo "$unclassified > $CONTAM_MAX_UNCLASSIFIED" | bc -l) )); then
        WARNINGS+=("high_unclassified:${unclassified}%")
    fi

    if [[ "$species_count" -gt "$CONTAM_MAX_SPECIES" ]]; then
        WARNINGS+=("mixed_isolate:${species_count}_species")
    fi

    if (( $(echo "$top_abundance < $CONTAM_MIN_DOMINANT" | bc -l) )); then
        WARNINGS+=("low_dominant:${top_abundance}%")
    fi

    if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
        STATUS="WARN: $(IFS=';'; echo "${WARNINGS[*]}")"
    fi

    echo -e "${sample_id}\t${species_count}\t${top_species}\t${top_abundance}\t${unclassified}\t${STATUS}" >> "$CONTAM_TSV"
done

echo "Contamination summary written to $CONTAM_TSV"

# ── Merge MetaPhlAn profiles ──────────────────────────────────────────────────
echo "Merging MetaPhlAn profiles..."
merge_metaphlan_tables.py "$MET_DIR"/*.unclprofile.txt \
    -o "$AGG_DIR/metaphlan_merged.tsv"
echo "Merged MetaPhlAn table written to $AGG_DIR/metaphlan_merged.tsv"

echo ""
echo "======================================================================"
echo "Aggregated QC outputs are ready in: $AGG_DIR"
echo ""
echo "Key outputs:"
echo "  MultiQC report  : $MULTIQC_DIR/multiqc_report.html"
echo "  Hostile summary : $HOSTILE_CSV"
echo "  Contamination   : $CONTAM_TSV"
echo "  MetaPhlAn merge : $AGG_DIR/metaphlan_merged.tsv"
echo ""
echo "Review contamination_summary.tsv before proceeding to assembly."
echo "When ready, run: bash 01_check_qc.sh"
echo "======================================================================"

echo "Job done"; date
