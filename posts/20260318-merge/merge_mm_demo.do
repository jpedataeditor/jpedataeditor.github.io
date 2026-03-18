********************************************************************************
* merge_mm_demo.do
*
* Demonstrates the difference between:
*   (1) merge m:m  — positional row-pairing within key groups (almost never
*                    what you want)
*   (2) joinby     — true relational many-to-many (Cartesian product within
*                    key groups)
*
* The example uses a firm with three employees and three contracts.
* There is no meaningful one-to-one correspondence between them —
* which is exactly what makes merge m:m dangerous.
********************************************************************************

clear all
set more off

********************************************************************************
* 1. BUILD THE TWO DATASETS
********************************************************************************

* --- employees.dta -----------------------------------------------------------
input str10 firm_id str8 employee
    "firm_42"   "Alice"
    "firm_42"   "Bob"
    "firm_42"   "Carol"
    "firm_99"   "Dave"
end

label var firm_id  "Firm identifier"
label var employee "Employee name"

save employees.dta, replace

* --- contracts.dta -----------------------------------------------------------
clear
input str10 firm_id str8 contract
    "firm_42"   "C-001"
    "firm_42"   "C-002"
    "firm_42"   "C-003"
    "firm_99"   "D-001"
end

label var firm_id  "Firm identifier"
label var contract "Contract reference"

save contracts.dta, replace


********************************************************************************
* 2. THE WRONG WAY: merge m:m
*
* Stata pairs rows by POSITION within each key group after sorting.
* The result depends entirely on the current sort order of both files.
* It is not a relational join.
********************************************************************************

use employees.dta, clear

display as text _newline ///
    "================================================" _newline ///
    "  WRONG: merge m:m (positional row-pairing)"     _newline ///
    "================================================"

merge m:m firm_id using contracts.dta

* Show the result — note Alice→C-001, Bob→C-002, Carol→C-003
* This is purely positional: re-sort either file and you get different pairs.
list firm_id employee contract _merge, sepby(firm_id) noobs

* All _merge == 3 gives false confidence that the merge "worked"
tab _merge


********************************************************************************
* 2a. DEMONSTRATE SORT-ORDER DEPENDENCE
*
* Reverse the order of contracts for firm_42 and re-run.
* The employee-contract pairs change — even though _merge is still all 3s.
********************************************************************************

use employees.dta, clear

* Reload contracts but reverse the order within firm_42
use contracts.dta, clear
gsort firm_id -contract          // reverse alphabetical order within firm
save contracts_reversed.dta, replace

use employees.dta, clear

display as text _newline ///
    "================================================"         _newline ///
    "  WRONG: merge m:m after reversing contracts"             _newline ///
    "  (same _merge=3, completely different pairs!)"           _newline ///
    "================================================"

merge m:m firm_id using contracts_reversed.dta

* Now Alice→C-003, Bob→C-002, Carol→C-001
* The 'result' changed just because we re-sorted the using file.
list firm_id employee contract _merge, sepby(firm_id) noobs


********************************************************************************
* 3. THE RIGHT WAY: joinby
*
* joinby produces the true relational many-to-many join:
* the full Cartesian product within each key group.
* Every (employee, contract) combination appears exactly once.
* The result does NOT depend on sort order.
********************************************************************************

use employees.dta, clear

display as text _newline ///
    "================================================" _newline ///
    "  CORRECT: joinby (Cartesian product per group)" _newline ///
    "================================================"

joinby firm_id using contracts.dta

list firm_id employee contract, sepby(firm_id) noobs

* For firm_42: 3 employees × 3 contracts = 9 rows (correct)
* For firm_99: 1 employee  × 1 contract  = 1 row  (correct)
display as text _newline "Row count: " _N " (expected 10 = 9 + 1)"


********************************************************************************
* 4. COMPARISON SUMMARY
********************************************************************************

display as text _newline ///
    "================================================" _newline ///
    "  SUMMARY"                                        _newline ///
    "================================================" _newline ///
    "  merge m:m  →  3 rows for firm_42 (positional," _newline ///
    "                 sort-order dependent, WRONG)"    _newline ///
    "  joinby     →  9 rows for firm_42 (Cartesian,"  _newline ///
    "                 relational, CORRECT)"            _newline ///
    "================================================"


********************************************************************************
* 5. WHAT YOU PROBABLY ACTUALLY WANTED
*
* In most real cases, merge m:m signals a missing key variable.
* The data probably has a meaningful unique key you haven't used yet.
*
* Example: if each employee is assigned to exactly one contract,
* add contract_id as a key variable and use merge 1:1.
********************************************************************************

* employees with explicit contract assignment
clear
input str10 firm_id str8 employee str8 contract_id
    "firm_42"   "Alice"   "C-001"
    "firm_42"   "Bob"     "C-002"
    "firm_42"   "Carol"   "C-003"
    "firm_99"   "Dave"    "D-001"
end
save employees_with_key.dta, replace

clear
input str10 firm_id str8 contract_id str20 contract_desc
    "firm_42"   "C-001"   "Software license"
    "firm_42"   "C-002"   "Consulting retainer"
    "firm_42"   "C-003"   "Hardware supply"
    "firm_99"   "D-001"   "Maintenance contract"
end
save contracts_with_key.dta, replace

use employees_with_key.dta, clear

display as text _newline ///
    "================================================"          _newline ///
    "  ALTERNATIVE: merge 1:1 once you identify the key"        _newline ///
    "================================================"

merge 1:1 firm_id contract_id using contracts_with_key.dta

list firm_id employee contract_id contract_desc _merge, sepby(firm_id) noobs
assert _merge == 3


********************************************************************************
* CLEAN UP
********************************************************************************

erase employees.dta
erase employees_with_key.dta
erase contracts.dta
erase contracts_reversed.dta
erase contracts_with_key.dta

display as text _newline "Done."
