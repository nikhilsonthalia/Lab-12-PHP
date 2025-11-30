source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/utils.R")
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/estimation.R")
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/simulation.R")
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/placement.R")
#' @param data_file Character path to usage data CSV
#' @param fleet_sizes Integer vector of fleet sizes to analyze
#' @param method Character estimation method ("binning" or "kernel")
#' @param n_sims Integer number of simulations
#' @param seed Integer random seed
#' @param output_dir Character directory for saving results
#' @export
run_pipeline <- function(data_file,
                         fleet_sizes = c(50, 100, 200),
                         method = "binning",
                         n_sims = 1000,
                         seed = 123,
                         output_dir = "results") {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  cat("Loading and preparing data...\n")
  usage_data <- load_and_prepare_data(data_file)
  validate_data(usage_data)
  cat("Estimating intensity functions for all stations...\n")
  intensity_list <- estimate_all_stations(usage_data, method = method)
  cat("Calculating expected demand...\n")
  expected_demand <- sapply(intensity_list, calculate_expected_demand)
  cat("Simulating daily demand scenarios...\n")
  simulated_demand <- simulate_daily_demand(intensity_list, 
                                            n_sims = n_sims, 
                                            seed = seed)
  cat("Generating intensity function plots...\n")
  p1 <- plot_intensity_functions(intensity_list)
  ggplot2::ggsave(file.path(output_dir, "intensity_functions.png"), 
                  p1, width = 10, height = 6)
  results_list <- list()
  for (fleet_size in fleet_sizes) {
    cat(sprintf("\nAnalyzing fleet size: %d bikes\n", fleet_size))
    placement_prop <- optimize_placement_proportional(expected_demand, fleet_size)
    placement_threshold <- optimize_placement_threshold(simulated_demand, fleet_size, 
                                                        percentile = 0.8)
    placement_greedy <- optimize_placement_greedy(simulated_demand, fleet_size, 
                                                  seed = seed)
    metrics_prop <- evaluate_placement(placement_prop, simulated_demand)
    metrics_threshold <- evaluate_placement(placement_threshold, simulated_demand)
    metrics_greedy <- evaluate_placement(placement_greedy, simulated_demand)
    best_strategy <- which.max(c(
      metrics_prop$coverage_rate,
      metrics_threshold$coverage_rate,
      metrics_greedy$coverage_rate
    ))
    strategy_names <- c("Proportional", "Threshold", "Greedy")
    placements <- list(placement_prop, placement_threshold, placement_greedy)
    metrics_all <- list(metrics_prop, metrics_threshold, metrics_greedy)
    best_placement <- placements[[best_strategy]]
    best_metrics <- metrics_all[[best_strategy]]
    cat(sprintf("Best strategy: %s (Coverage: %.2f%%)\n", 
                strategy_names[best_strategy], 
                best_metrics$coverage_rate * 100))
    summary_table <- create_summary_table(best_placement, expected_demand, best_metrics)
    fleet_dir <- file.path(output_dir, sprintf("fleet_%d", fleet_size))
    if (!dir.exists(fleet_dir)) {
      dir.create(fleet_dir, recursive = TRUE)
    }
    write.csv(summary_table, 
              file.path(fleet_dir, "allocation_table.csv"),
              row.names = FALSE)
    metrics_df <- data.frame(
      Metric = c("Coverage Rate", "Coverage SD", "Utilization Rate", 
                 "Utilization SD", "Avg Shortages"),
      Value = c(best_metrics$coverage_rate, best_metrics$coverage_sd,
                best_metrics$utilization_rate, best_metrics$utilization_sd,
                best_metrics$avg_shortages)
    )
    write.csv(metrics_df, 
              file.path(fleet_dir, "performance_metrics.csv"),
              row.names = FALSE)
    p3 <- plot_allocation_barplot(best_placement)
    ggplot2::ggsave(file.path(fleet_dir, "allocation_barplot.png"), 
                    p3, width = 10, height = 6)
    results_list[[as.character(fleet_size)]] <- list(
      placement = best_placement,
      metrics = best_metrics,
      strategy = strategy_names[best_strategy]
    )
  }
  cat("\nPipeline complete! Results saved to:", output_dir, "\n")
  return(invisible(results_list))
}
