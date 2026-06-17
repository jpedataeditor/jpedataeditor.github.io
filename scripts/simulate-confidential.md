# /simulate-confidential — Confidential Data Simulator

Generate a simulation script that produces fake versions of all confidential raw input files
in this replication package, satisfying the JPE Data Editor's requirements for a
simulated-data submission.

## When invoked

The user may specify a language preference. If not specified, choose the language that makes
the task easiest — typically Python or Julia for their strong data-generation libraries —
**regardless of what language the analysis pipeline uses**. The simulation script only needs
to produce output files in the correct format and at the correct paths; it does not need to
share a language with the analysis code.

---

## Step 1 — Locate all confidential data reads

Search every code file for file-read operations. Common patterns by language:

- **Stata**: `use`, `import delimited`, `import excel`, `insheet`, `odbc load`
- **R**: `read.csv`, `read_csv`, `read_dta`, `haven::read_dta`, `fread`, `readRDS`, `load(`
- **Python**: `pd.read_csv`, `pd.read_stata`, `pd.read_excel`, `pd.read_parquet`, `np.load`, `open(`
- **Julia**: `CSV.read`, `CSV.File`, `XLSX.readtable`, `readdlm`, `load` (FileIO), `Arrow.Table`
- **Matlab**: `readtable`, `readmatrix`, `load`, `xlsread`, `importdata`
- **Other languages**: look for any function call that takes a file path string as its first argument

For each read, record:
- The exact file path/name being read
- The variable names subsequently used from that file (follow merges, keeps, selects, renames)

Focus only on files that are not already present in the package (i.e. the confidential ones the
pipeline cannot run without).

---

## Step 2 — Collect variable metadata

Search the following sources for information about each variable:

1. `README` file — variable descriptions, units, codebook sections
2. Any separate codebook or data dictionary files
3. Comments in the code near read statements
4. Stata `label variable` / `label define` commands
5. Summary statistics tables in the paper or appendix (if accessible)

For each variable, determine:
- **Data type**: continuous, integer, binary (0/1), categorical (fixed value set), date, string
- **Sign / support restriction**: always positive, bounded on [0,1], takes values in a fixed set
  {a, b, c, …}, non-negative integer, etc.
- **Panel role**: unit identifier, time identifier, time-varying outcome/covariate, or
  time-invariant characteristic (constant within panel unit)

If a restriction cannot be determined from code or documentation, flag it explicitly in the
report (Step 5) for the author to review before submission.

---

## Step 3 — Identify dataset structure

From the code determine:

- Panel or cross-section?
- Unit identifier variable(s) (firm, person, country, …)
- Time identifier variable (year, quarter, …) if panel
- Approximate number of observations (from README, summary stats, or hard-coded locals in code)
- Every group/cell the code conditions on (bysort keys, group_by variables, merge keys,
  subgroup fixed effects) — the simulated data must have at least one observation in each

---

## Step 4 — Write the simulation script

Generate a complete, self-contained simulation script that:

1. Sets random seed `42` at the top
2. For each confidential input file:
   - Creates the panel / cross-section structure (unit × time grid if applicable)
   - Simulates each variable respecting type and support:
     - Always-positive continuous → log-normal (`exp(normal(μ, σ))`)
     - Positive integer → `max(1, round(exp(normal(μ, σ))))`
     - Binary → Bernoulli with p ≈ 0.4–0.6
     - Categorical {1…K} → uniform draw from the set
     - Date → sequential or uniform draw within a plausible range
     - String identifier → sequential labels ("firm_1", "firm_2", …)
   - Assigns time-invariant characteristics at the unit level, then broadcast to all rows
   - Ensures every group/cell identified in Step 3 is represented
3. Saves each file in the **exact format and path** the code expects (`.dta`, `.csv`, etc.)

Save the script to `code/simulate/simulate_confidential.<ext>` using the chosen language
(create the folder if absent). The extension should match the language used (`.py`, `.jl`,
`.R`, `.do`, `.m`, etc.).

---

## Step 5 — Report

After writing the script, print a concise report:

| File | Dimensions | Variables | Flags |
|------|-----------|-----------|-------|

- **File**: path the code reads
- **Dimensions**: rows × columns
- **Variables**: comma-separated list with type and restriction noted
- **Flags**: variables where type or support could not be determined — author must review these
  before submitting the package to the Data Editor

Also print the command to run the simulation script so the author can test it immediately.
