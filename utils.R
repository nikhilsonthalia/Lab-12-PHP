#' @param file_path Character string path to CSV file
#' @param date_col Character name of timestamp column
#' @param station_col Character name of station ID column
#' @return data.frame with standardized columns: station_id, timestamp, hour, day_of_week
#' @export
load_and_prepare_data <- function(file_path, 
                                  date_col = "start_time", 
                                  station_col = "start_station") {
  
  data <- read.csv(file_path, stringsAsFactors = FALSE)
  if (!date_col %in% names(data)) {
    stop(paste("Column", date_col, "not found in data"))
  }
  if (!station_col %in% names(data)) {
    stop(paste("Column", station_col, "not found in data"))
  }
  data$timestamp <- as.POSIXct(data[[date_col]], tz = "UTC")
  data$station_id <- as.character(data[[station_col]])
  data$hour <- as.numeric(format(data$timestamp, "%H"))
  data$minute <- as.numeric(format(data$timestamp, "%M"))
  data$day_of_week <- weekdays(data$timestamp)
  data$date <- as.Date(data$timestamp)
  data <- data[, c("station_id", "timestamp", "hour", "minute", "day_of_week", "date")]
  data <- data[complete.cases(data), ]
  data <- data[data$station_id != "R", ]
  cat(sprintf("Loaded %d trips from %d stations\n", 
              nrow(data), 
              length(unique(data$station_id))))
  cat(sprintf("Date range: %s to %s\n", 
              min(data$date), 
              max(data$date)))
  return(data)
}
#' @param usage_data data.frame with bike usage data
#' @return Logical TRUE if valid, throws error otherwise
#' @export
validate_data <- function(usage_data) {
  required_cols <- c("station_id", "timestamp", "hour")
  if (!all(required_cols %in% names(usage_data))) {
    stop(paste("Data must contain columns:", paste(required_cols, collapse = ", ")))
  }
  if (nrow(usage_data) == 0) {
    stop("Data cannot be empty")
  }
  if (!inherits(usage_data$timestamp, "POSIXct")) {
    stop("timestamp must be POSIXct format")
  }
  return(TRUE)
}
#' @param timestamps POSIXct vector of arrival times
#' @param n_bins Integer number of time bins (default 24 for hourly)
#' @return List with bin_centers (numeric) and rates (numeric)
#' @export
bin_hourly_rates <- function(timestamps, n_bins = 24) {
  hours <- as.numeric(format(timestamps, "%H")) + 
    as.numeric(format(timestamps, "%M")) / 60
  bin_edges <- seq(0, 24, length.out = n_bins + 1)
  bin_centers <- (bin_edges[-1] + bin_edges[-(n_bins + 1)]) / 2
  counts <- hist(hours, breaks = bin_edges, plot = FALSE)$counts
  total_days <- length(unique(as.Date(timestamps)))
  rates <- counts / total_days
  return(list(
    bin_centers = bin_centers,
    rates = rates
  ))
}
#' @param times Numeric vector of time points
#' @param intensities Numeric vector of intensity values
#' @return Numeric scalar (integral value)
#' @export
integrate_intensity <- function(times, intensities) {
  if (length(times) != length(intensities)) {
    stop("times and intensities must have same length")
  }
  if (length(times) < 2) {
    return(0)
  }
  dt <- diff(times)
  avg_intensity <- (intensities[-1] + intensities[-length(intensities)]) / 2
  return(sum(dt * avg_intensity))
}
#' @param intensity_list List of intensity functions (one per station)
#' @param station_ids Character vector of station IDs to plot (NULL for all)
#' @param max_stations Integer maximum number of stations to plot
#' @return ggplot object
#' @import ggplot2
#' @export
plot_intensity_functions <- function(intensity_list, 
                                     station_ids = NULL, 
                                     max_stations = 6) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package ggplot2 is required for plotting")
  }
  if (is.null(station_ids)) {
    total_rates <- sapply(intensity_list, function(x) x$total_rate)
    station_ids <- names(sort(total_rates, decreasing = TRUE))[1:min(max_stations, length(intensity_list))]
  }
  plot_data <- do.call(rbind, lapply(station_ids, function(sid) {
    if (sid %in% names(intensity_list)) {
      data.frame(
        station_id = sid,
        time = intensity_list[[sid]]$times,
        intensity = intensity_list[[sid]]$intensities
      )
    }
  }))
  ggplot2::ggplot(plot_data, ggplot2::aes(x = time, y = intensity, color = station_id)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::labs(
      title = "Estimated Arrival Intensity by Station",
      x = "Hour of Day",
      y = "Arrival Rate (trips/hour)",
      color = "Station ID"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::scale_x_continuous(breaks = seq(0, 24, 4))
}
#' @param placement Named integer vector of bikes per station
#' @param top_n Integer number of top stations to show
#' @return ggplot object
#' @import ggplot2
#' @export
plot_allocation_barplot <- function(placement, top_n = 15) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package ggplot2 is required for plotting")
  }
  placement_sorted <- sort(placement, decreasing = TRUE)[1:min(top_n, length(placement))]
  plot_data <- data.frame(
    station_id = factor(names(placement_sorted), levels = names(placement_sorted)),
    bikes = as.numeric(placement_sorted)
  )
  ggplot2::ggplot(plot_data, ggplot2::aes(x = station_id, y = bikes)) +
    ggplot2::geom_bar(stat = "identity", fill = "steelblue") +
    ggplot2::labs(
      title = paste("Recommended Bike Allocation (Top", top_n, "Stations)"),
      x = "Station ID",
      y = "Number of Bikes"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}
#' @param placement Named integer vector of bikes per station
#' @param expected_demand Numeric vector of expected daily arrivals per station
#' @param metrics List containing evaluation metrics
#' @return data.frame formatted summary table
#' @export
create_summary_table <- function(placement, expected_demand, metrics = NULL) {
  summary_df <- data.frame(
    Station_ID = names(placement),
    Bikes_Allocated = as.numeric(placement),
    Expected_Daily_Arrivals = round(expected_demand[names(placement)], 1),
    stringsAsFactors = FALSE
  )
  summary_df$Utilization_Ratio <- round(
    summary_df$Expected_Daily_Arrivals / summary_df$Bikes_Allocated, 2
  )
  summary_df <- summary_df[order(summary_df$Bikes_Allocated, decreasing = TRUE), ]
  return(summary_df)
}