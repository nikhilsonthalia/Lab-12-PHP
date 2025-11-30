#' @param usage_data data.frame with bike usage data
#' @param station_id Character station identifier
#' @param method Character "binning" or "kernel" for estimation method
#' @param n_bins Integer number of time bins for binning method
#' @return List with times, intensities, and total_rate
#' @export
estimate_intensity_function <- function(usage_data, 
                                        station_id, 
                                        method = "binning",
                                        n_bins = 24) {
  station_data <- usage_data[usage_data$station_id == station_id, ]
  if (nrow(station_data) == 0) {
    warning(paste("No data for station", station_id))
    return(list(
      times = seq(0, 24, length.out = n_bins),
      intensities = rep(0, n_bins),
      total_rate = 0
    ))
  }
  if (method == "binning") {
    binned <- bin_hourly_rates(station_data$timestamp, n_bins = n_bins)
    return(list(
      times = binned$bin_centers,
      intensities = binned$rates,
      total_rate = sum(binned$rates * (24 / n_bins))
    ))
  } else if (method == "kernel") {
    hours <- as.numeric(format(station_data$timestamp, "%H")) + 
      as.numeric(format(station_data$timestamp, "%M")) / 60
    times <- seq(0, 24, length.out = n_bins)
    bandwidth <- 1.5
    intensities <- sapply(times, function(t) {
      weights <- dnorm(hours - t, sd = bandwidth)
      mean(weights) * length(hours) / length(unique(station_data$date))
    })
    return(list(
      times = times,
      intensities = intensities,
      total_rate = integrate_intensity(times, intensities)
    ))
  } else {
    stop("method must be 'binning' or 'kernel'")
  }
}
#' @param usage_data data.frame with bike usage data
#' @param method Character "binning" or "kernel"
#' @param n_bins Integer number of time bins
#' @return Named list of intensity functions, one per station
#' @export
estimate_all_stations <- function(usage_data, method = "binning", n_bins = 24) {
  validate_data(usage_data)
  stations <- unique(usage_data$station_id)
  intensity_list <- lapply(stations, function(sid) {
    estimate_intensity_function(usage_data, sid, method = method, n_bins = n_bins)
  })
  names(intensity_list) <- stations
  return(intensity_list)
}
#' @param intensity_function List with times and intensities
#' @return Numeric scalar (expected daily arrivals)
#' @export
calculate_expected_demand <- function(intensity_function) {
  return(intensity_function$total_rate)
}

