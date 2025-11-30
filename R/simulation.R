#' @param intensity_list List of intensity functions (one per station)
#' @param n_sims Integer number of simulation runs
#' @param seed Integer random seed for reproducibility
#' @return Matrix where rows = stations, cols = simulations
#' @export
simulate_daily_demand <- function(intensity_list, n_sims = 1000, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  stations <- names(intensity_list)
  n_stations <- length(stations)
  demand_matrix <- matrix(0, nrow = n_stations, ncol = n_sims)
  rownames(demand_matrix) <- stations
  for (i in seq_along(stations)) {
    sid <- stations[i]
    intensity_fn <- intensity_list[[sid]]
    lambda_total <- intensity_fn$total_rate
    demand_matrix[i, ] <- rpois(n_sims, lambda = lambda_total)
  }
  return(demand_matrix)
}
#' @param placement Named integer vector of bikes per station
#' @param simulated_demand Matrix of simulated demand (rows = stations, cols = sims)
#' @return List with performance metrics
#' @export
evaluate_placement <- function(placement, simulated_demand) {
  stations <- names(placement)
  demand_subset <- simulated_demand[stations, , drop = FALSE]
  n_sims <- ncol(demand_subset)
  coverage <- sapply(1:n_sims, function(j) {
    demand <- demand_subset[, j]
    supplied <- pmin(demand, placement)
    sum(supplied) / max(sum(demand), 1)
  })
  utilization <- sapply(1:n_sims, function(j) {
    demand <- demand_subset[, j]
    used <- pmin(demand, placement)
    sum(used) / max(sum(placement), 1)
  })
  shortages <- sapply(1:n_sims, function(j) {
    demand <- demand_subset[, j]
    sum(demand > placement)
  })
  return(list(
    coverage_rate = mean(coverage),
    coverage_sd = sd(coverage),
    utilization_rate = mean(utilization),
    utilization_sd = sd(utilization),
    avg_shortages = mean(shortages),
    coverage_percentiles = quantile(coverage, probs = c(0.05, 0.25, 0.5, 0.75, 0.95))
  ))
}