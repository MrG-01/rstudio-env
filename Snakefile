# ── Snakefile ─────────────────────────────────────────────────────────────────
# Run with:  snakemake --cores 1
# ──────────────────────────────────────────────────────────────────────────────

import os
from pathlib import Path

# ── Configuration ─────────────────────────────────────────────────────────────
INPUT_DIR  = "input"
OUTPUT_DIR = "output"
SCRIPT_DIR = "scripts"

# Discover input data files
DATA_EXTENSIONS = [".csv", ".tsv", ".xls", ".xlsx"]
INPUT_FILES = [
    f.name for f in Path(INPUT_DIR).iterdir()
    if f.suffix.lower() in DATA_EXTENSIONS
] if Path(INPUT_DIR).exists() else []

# Derive basenames (without extension) for wildcard matching
SAMPLES = [Path(f).stem for f in INPUT_FILES]

# ── Default rule: request all final outputs ───────────────────────────────────
rule all:
    input:
        expand(os.path.join(OUTPUT_DIR, "{sample}.rds"), sample=SAMPLES)


# ── Rule: load & save each input file as an .rds ─────────────────────────────
rule load_data:
    input:
        script = os.path.join(SCRIPT_DIR, "load_data.R"),
        data   = lambda wc: [
            f for f in
            [os.path.join(INPUT_DIR, f"{wc.sample}{ext}") for ext in DATA_EXTENSIONS]
            if os.path.exists(f)
        ][0]
    output:
        rds = os.path.join(OUTPUT_DIR, "{sample}.rds")
    log:
        os.path.join("logs", "load_data", "{sample}.log")
    shell:
        """
        Rscript {input.script} {input.data} {output.rds} > {log} 2>&1
        """
