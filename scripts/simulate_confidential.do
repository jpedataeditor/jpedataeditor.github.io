clear
set seed 42

* --- dimensions ---
local n_firms  200
local n_years  10
local N = `n_firms' * `n_years'

set obs `N'

* firm and year identifiers
gen id   = ceil(_n / `n_years')
gen year = 1990 + mod(_n - 1, `n_years')

* positive continuous variable (log-normal)
gen revenue    = exp(rnormal(10, 1))

* positive integer
gen employment = max(1, round(exp(rnormal(4, 0.8))))

* binary treatment (assigned at firm level so it is constant within firm)
bysort id (year): gen treated = (runiform() < 0.4) if _n == 1
bysort id: replace treated = treated[1]

* categorical sector (1–4), assigned at firm level
bysort id (year): gen sector = ceil(runiform() * 4) if _n == 1
bysort id: replace sector = sector[1]

* label and save
label variable revenue    "Annual revenue (USD)"
label variable employment "Number of employees"
label variable treated    "Treatment indicator"
label variable sector     "Sector (1–4)"

save "data/raw/simulated_panel.dta", replace
