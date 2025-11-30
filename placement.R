#' @param expected_demand Named numeric vector of expected daily arrivals
#' @param total_bikes Integer total number of bikes available
#' @return Named integer vector of bikes per station
#' @export
optimize_placement_proportional <- function(expected_demand, total_bikes) {
  if (total_bikes < 1) {
    stop("total_bikes must be at least 1")
  }
  demand_positive <- expected_demand[expected_demand > 0]
  if (length(demand_positive) == 0) {
    warning("No stations with positive demand")
    return(integer(0))
  }
  proportions <- demand_positive / sum(demand_positive)
  allocation <- proportions * total_bikes
  allocation_floor <- floor(allocation)
  remaining <- total_bikes - sum(allocation_floor)
  if (remaining > 0) {
    fractional_parts <- allocation - allocation_floor
    top_stations <- order(fractional_parts, decreasing = TRUE)[1:remaining]
    allocation_floor[top_stations] <- allocation_floor[top_stations] + 1
  }
  return(allocation_floor)
}
#' @param simulated_demand Matrix of simulated demand
#' @param total_bikes Integer total number of bikes available
#' @param percentile Numeric percentile of demand to cover (default 0.8)
#' @return Named integer vector of bikes per station
#' @export
optimize_placement_threshold <- function(simulated_demand, 
                                         total_bikes, 
                                         percentile = 0.8) {
  if (total_bikes < 1) {
    stop("total_bikes must be at least 1")
  }
  percentile_demand <- apply(simulated_demand, 1, quantile, probs = percentile)
  allocation <- optimize_placement_proportional(percentile_demand, total_bikes)
  return(allocation)
}

#' @param simulated_demand Matrix of simulated demand
#' @param total_bikes Integer total number of bikes available
#' @param seed Integer random seed for reproducibility
#' @return Named integer vector of bikes per station
#' @export
optimize_placement_greedy <- function(simulated_demand, total_bikes, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  stations <- rownames(simulated_demand)
  n_stations <- nrow(simulated_demand)
  allocation <- rep(0, n_stations)
  names(allocation) <- stations
  for (bike in 1:total_bikes) {
    marginal_benefit <- sapply(1:n_stations, function(i) {
      current_alloc <- allocation[i]
      mean(pmin(simulated_demand[i, ], current_alloc + 1) - 
             pmin(simulated_demand[i, ], current_alloc))
    })
    best_station <- which.max(marginal_benefit)
    allocation[best_station] <- allocation[best_station] + 1
  }
  
  return(allocation)
}