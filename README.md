# Bike-Share Placement Optimization Pipeline

This R pipeline optimizes the initial placement of bikes in a bike-share system using Non-Homogeneous Poisson Processes (NHPPs) to model user demand patterns throughout the day.

## Project Structure

The project contains five R scripts in the R/ folder: utils.R handles data loading and visualization, estimation.R estimates intensity functions for each station, simulation.R runs Monte Carlo simulations of daily demand, placement.R implements three optimization strategies (proportional, threshold-based, and greedy), and main.R orchestrates the complete pipeline. The tests/ folder contains testthat.R with unit tests. Input data goes in the data/ folder, and outputs are automatically generated in the results/ folder.

## Requirements

Install required packages by running: install.packages(c("ggplot2", "testthat"))

## How to Run

First, place your bike usage CSV file in the data/ folder. Your CSV must have columns named start_time (timestamp) and start_station (station ID). Then open RStudio, set your working directory to the project folder, and load the pipeline with source("R/main.R"). Run the analysis with: results <- run_pipeline(data_file = "data/your_file.csv", fleet_sizes = c(50, 100, 200)). The pipeline will automatically create a results/ folder containing allocation tables, performance metrics, and visualizations for each fleet size.

## Understanding the Outputs

For each fleet size, the pipeline generates three files in a fleet_X subfolder. The allocation_table.csv shows how many bikes to place at each station, along with expected daily arrivals and utilization ratios. The performance_metrics.csv contains coverage rate (percentage of demand satisfied), utilization rate (percentage of bikes used), and average shortages per day. Three PNG files visualize the results: intensity_functions.png shows demand patterns throughout the day, demand_heatmap.png displays hourly demand across stations, and allocation_barplot.png summarizes the bike distribution.

## Methodology

The pipeline models each station's arrival process as a non-homogeneous Poisson process with time-varying intensity. It estimates intensity functions from historical data using binning or kernel density methods, then runs Monte Carlo simulations to generate thousands of possible demand scenarios. Three optimization strategies are compared: proportional allocation distributes bikes based on expected demand, threshold allocation targets the 80th percentile of demand, and greedy allocation maximizes marginal benefit. The best-performing strategy is automatically selected based on demand coverage rate.

## Running Tests

To verify the pipeline works correctly, run: source("tests/testthat.R"). The tests check that core functions produce correct outputs including binning calculations, numerical integration, allocation constraints, simulation dimensions, and evaluation metrics.

## Interpreting Results

The allocation table shows recommended bike placement, with higher allocations indicating busier stations. Utilization ratios between 10-15 suggest good balance, while ratios above 20 indicate stations may need more bikes. Coverage rate shows what percentage of demand can be satisfied (75-95% is typical), and utilization rate shows how efficiently bikes are used (70-95% is good). Comparing fleet sizes reveals diminishing returns, where doubling the fleet size does not double the coverage. The intensity plots reveal commuter patterns with peaks during morning and evening rush hours.

## Example Usage

Load the pipeline and run analysis: source("R/main.R") then results <- run_pipeline(data_file = "data/sample_bike.csv", fleet_sizes = c(50, 100, 200), n_sims = 1000, seed = 123). View results: list.files("results") and allocation <- read.csv("results/fleet_50/allocation_table.csv"). The pipeline takes 1-3 minutes to complete depending on data size and number of simulations.

## Data Format

Your input CSV must contain start_time (timestamp format YYYY-MM-DD HH:MM:SS) and start_station (station identifier) columns. The pipeline automatically filters out station "R" which represents depot returns. Other columns like end_station, end_time, and customer_type are optional and will be ignored. Multiple days of historical data are recommended for accurate intensity estimates.

## Customization

Modify parameters in run_pipeline() to customize analysis. Change fleet_sizes to test different numbers of bikes, set method to "binning" (faster) or "kernel" (smoother), adjust n_sims for more robust estimates (default 1000), set seed for reproducible results, or change output_dir to save results elsewhere.

## Authors

Statistical Programming Lab Assignment

## License

Academic use only.
