#!/usr/bin/env python3

import sys
from pathlib import Path
from openpyxl import Workbook

input_dir = Path(sys.argv[1])
output_file = sys.argv[2]

wb = Workbook()
ws = wb.active
ws.title = "All_pheno_tables"

row_num = 1

for folder in sorted(input_dir.iterdir()):
    if not folder.is_dir():
        continue

    sample = folder.name
    pheno_file = folder / "pheno_table.txt"

    if not pheno_file.exists():
        print(f"Skipping {sample}: no pheno_table.txt")
        continue

    with open(pheno_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")

            if line.startswith("#"):
                ws.cell(row=row_num, column=1, value=sample)
                ws.cell(row=row_num, column=2, value=line)
            elif line.strip() == "":
                ws.cell(row=row_num, column=1, value=sample)
            else:
                parts = line.split("\t")
                ws.cell(row=row_num, column=1, value=sample)
                for i, value in enumerate(parts, start=2):
                    ws.cell(row=row_num, column=i, value=value)

            row_num += 1

    row_num += 1   # blank row between isolates

wb.save(output_file)

print(f"Created: {output_file}")
