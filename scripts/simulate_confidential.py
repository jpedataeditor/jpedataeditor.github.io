import numpy as np
import pandas as pd

rng = np.random.default_rng(seed=42)

n_firms = 200
n_years = 10
years   = range(1990, 1990 + n_years)

# firm-level characteristics
firms = pd.DataFrame({
    "id":      np.arange(1, n_firms + 1),
    "treated": rng.binomial(1, 0.4, n_firms),
    "sector":  rng.integers(1, 5, n_firms),   # 1, 2, 3, or 4
})

# expand to panel
panel = firms.loc[firms.index.repeat(n_years)].copy()
panel["year"] = list(years) * n_firms
panel = panel.reset_index(drop=True)

# observation-level variables
panel["revenue"]    = np.exp(rng.normal(10, 1, len(panel)))
panel["employment"] = np.maximum(1, rng.lognormal(4, 0.8, len(panel)).round().astype(int))

panel = panel.sort_values(["id", "year"]).reset_index(drop=True)

panel.to_csv("data/raw/simulated_panel.csv", index=False)
