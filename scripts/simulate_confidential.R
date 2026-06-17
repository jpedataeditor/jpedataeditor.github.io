set.seed(42)

n_firms <- 200
n_years <- 10

panel <- expand.grid(
  id   = 1:n_firms,
  year = 1990:(1990 + n_years - 1)
)

# firm-level variables (constant within firm)
firm_chars <- data.frame(
  id       = 1:n_firms,
  treated  = as.integer(runif(n_firms) < 0.4),
  sector   = sample(1:4, n_firms, replace = TRUE)
)

panel <- merge(panel, firm_chars, by = "id")

# observation-level variables
panel$revenue    <- exp(rnorm(nrow(panel), mean = 10, sd = 1))
panel$employment <- pmax(1L, round(exp(rnorm(nrow(panel), 4, 0.8))))

panel <- panel[order(panel$id, panel$year), ]

# save as csv (or use haven::write_dta for .dta)
write.csv(panel, "data/raw/simulated_panel.csv", row.names = FALSE)
