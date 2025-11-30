library(testthat)
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/utils.R")
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/estimation.R")
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/simulation.R")
source("/Users/nikhilsonthalia/Downloads/Lab-12-PHP-/R/placement.R")
test_that("bin_hourly_rates produces correct output structure", {
  timestamps <- as.POSIXct(c(
    "2024-01-01 08:00:00",
    "2024-01-01 08:30:00",
    "2024-01-01 09:15:00",
    "2024-01-02 08:00:00"
  ), tz = "UTC")
  result <- bin_hourly_rates(timestamps, n_bins = 24)
  expect_type(result, "list")
  expect_named(result, c("bin_centers", "rates"))
  expect_length(result$bin_centers, 24)
  expect_length(result$rates, 24)
  expect_true(all(result$rates >= 0))
})

test_that("optimize_placement_proportional allocates correctly", {
  demand <- c(10, 20, 30)
  names(demand) <- c("A", "B", "C")
  total_bikes <- 60
  placement <- optimize_placement_proportional(demand, total_bikes)
  expect_equal(sum(placement), total_bikes)
  expect_true(all(placement >= 0))
  expect_equal(names(placement), c("A", "B", "C"))
  expect_true(placement["C"] > placement["B"])
  expect_true(placement["B"] > placement["A"])
})

test_that("simulate_daily_demand produces correct dimensions", {
  intensity_list <- list(
    "Station1" = list(times = seq(0, 24, length.out = 24),
                      intensities = rep(1, 24),
                      total_rate = 24),
    "Station2" = list(times = seq(0, 24, length.out = 24),
                      intensities = rep(2, 24),
                      total_rate = 48)
  )
  n_sims <- 100
  result <- simulate_daily_demand(intensity_list, n_sims = n_sims, seed = 42)
  expect_equal(nrow(result), 2)
  expect_equal(ncol(result), n_sims)
  expect_equal(rownames(result), c("Station1", "Station2"))
  expect_true(all(result >= 0))
})

test_that("evaluate_placement returns valid metrics", {
  placement <- c(5, 10, 15)
  names(placement) <- c("A", "B", "C")
  simulated_demand <- matrix(
    c(4, 8, 12,
      6, 12, 18,
      3, 9, 10),
    nrow = 3,
    byrow = TRUE
  )
  rownames(simulated_demand) <- c("A", "B", "C")
  metrics <- evaluate_placement(placement, simulated_demand)
  expect_type(metrics, "list")
  expect_true(metrics$coverage_rate >= 0 && metrics$coverage_rate <= 1)
  expect_true(metrics$utilization_rate >= 0 && metrics$utilization_rate <= 1)
  expect_true(metrics$avg_shortages >= 0)
})

test_that("validate_data catches invalid data", {
  valid_data <- data.frame(
    station_id = c("A", "B"),
    timestamp = as.POSIXct(c("2024-01-01 08:00:00", "2024-01-01 09:00:00"), tz = "UTC"),
    hour = c(8, 9)
  )
  expect_true(validate_data(valid_data))
  invalid_data <- data.frame(
    station_id = c("A", "B"),
    hour = c(8, 9)
  )
  expect_error(validate_data(invalid_data))
  empty_data <- valid_data[FALSE, ]
  expect_error(validate_data(empty_data))
})


cat("\nAll tests completed!\n")
