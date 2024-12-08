# set working directory
setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(ggplot2)
library(gridExtra)
library(lubridate)
library(dplyr)
library(forecast)
library(zoo)

# read the raw CSV file into a data frame
mydata <- read.csv("final_data_readings.csv", header = TRUE)

# convert 'created_at' column to datetime format (POSIXct)
mydata$created_at <- ymd_hms(mydata$created_at)

# round 'created_at' to the nearest minute to ignore seconds (due to approx 1s accumulative error on each reading)
mydata$created_at <- floor_date(mydata$created_at, "minute")

# initialise an empty dataframe to store missing rows
missing_rows <- data.frame()

# iterate through the timestamps and check for missing entries
for (i in 1:(nrow(mydata) - 1)) {
  current_time <- mydata$created_at[i]
  next_time <- mydata$created_at[i + 1]
  
  # check the difference between the consecutive times
  time_diff <- difftime(next_time, current_time, units = "mins")
  
  # if the difference is greater than 6 minutes, consider it as a missing time
  while (time_diff > 6) {
    current_time <- current_time + minutes(5)  # add 5 minutes to current time
    
    # create a new row with the missing timestamp
    missing_row <- data.frame(created_at = current_time)
    
    # append missing row to the missing_rows dataframe
    missing_rows <- rbind(missing_rows, missing_row)
    
    # print missing row
    print(paste("Missing time:", format(current_time, "%Y-%m-%dT%H:%M:%S+00:00")))
    
    # update the time difference for the next iteration
    time_diff <- difftime(next_time, current_time, units = "mins")
  }
}

# combine the original dataframe with identified missing rows
mydata <- bind_rows(mydata, missing_rows)

# sort the dataframe by the 'created_at' column
mydata <- mydata %>% arrange(created_at)

# Reassign the entry_id column as a continuous sequence starting from 1 (this is not necessary but done for full completeness)
mydata$entry_id <- seq(1, nrow(mydata))





######################## grand mean imputation #################################
## option 1 - grand mean imputation code

# grand_mean <- mean(mydata$humidity, na.rm = TRUE)
# 
# # impute missing humidity values with the grand mean
# mydata$humidity[is.na(mydata$humidity)] <- grand_mean
# 
# # plotting humidity with grand mean imputation
# cat("Plotting humidity readings with grand mean imputation...\n")
# 
# # create plot
# humidity_plot <- ggplot(mydata, aes(x = created_at, y = humidity)) +
#   geom_line(color = "blue") +
#   labs(
#     title = "Humidity Readings Over Time (Grand Mean Imputation)",
#     x = "Time",
#     y = "Humidity (%)"
#   ) +
#   theme_minimal() +
#   theme(
#     axis.text.x = element_text(angle = 0, hjust = 1), 
#     plot.title = element_text(hjust = 0.5)      
#   )
# 
# # display the plot
# print(humidity_plot)






###################### linear interpolation method  ############################

# linear interpolation to fill NA values
mydata$humidity <- na.approx(mydata$humidity)                                   # humidity
mydata$temperature <- na.approx(mydata$temperature)                             # temperature
mydata$api_temperature <- na.approx(mydata$api_temperature)                     # api temperature
mydata$api_humidity <- na.approx(mydata$api_humidity, na.rm = FALSE)            # api humidity
mydata$api_clouds <- na.approx(mydata$api_clouds, na.rm = FALSE)                # api clouds
mydata$api_windspeed <- na.approx(mydata$api_windspeed, na.rm = FALSE)          # api windspeed

# save the updated dataframe to a new CSV file
write.csv(mydata, "final_data_readings_updated.csv", row.names = FALSE)

# print the final list of missing rows so can see in console
if (nrow(missing_rows) > 0) {
  print("Summary of missing rows added:")
  print(missing_rows)
} else {
  print("No missing rows were identified.")
}

# read the updated data from CSV so that we can plot the graphs with new values
mydata2 <- read.csv("final_data_readings_updated.csv", header = TRUE)

# humidity data for moving average calculation
humidity_data <- mydata2$humidity
moving_average_humidity <- forecast::ma(humidity_data, order = 10, centre = TRUE)





### plotting the graphs (saving to png files directly in working directory) ####

# function to create plots with custom x-axis and different colors
create_plot <- function(data, y_variable, title, filename, moving_avg = NULL, line_color = "blue", ma_color = "red") {
  plot <- ggplot(data, aes(x = created_at, y = .data[[y_variable]])) +
    geom_line(col = line_color)  # Plot raw data
  
  # add moving average if provided
  if (!is.null(moving_avg)) {
    plot <- plot + geom_line(aes(y = moving_avg), col = ma_color, lwd = 1) 
  }
  
  plot <- plot + labs(title = title, x = "Time", y = y_variable) +
    theme_minimal() +
    scale_x_datetime(
      breaks = seq(from = min(data$created_at), to = max(data$created_at), by = "6 hours"),  # set 6 hour intervals
      labels = scales::date_format("%b %d %H:%M"),  # format the date and time labels
      expand = c(0, 0) 
    ) +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))  # Rotate x-axis labels to 90 degrees
  
  # save the plot to a file
  ggsave(filename, plot = plot, width = 8, height = 6)
  # print(plot)
}



# plotting all graphs with interpolated values

# Humidity with Moving Average
create_plot(mydata, "humidity", "Humidity Over Time with Moving Average", "humidity_with_moving_avg.png", moving_average_humidity, line_color = "blue", ma_color = "red")

# # plot for Humidity
# create_plot(mydata, "humidity", "Humidity Over Time", "humidity_over_time.png", line_color = "blue")

# # plot for Temperature
# create_plot(mydata, "temperature", "Temperature Over Time", "temperature_over_time.png", line_color = "red")

# # plot for API Temperature
# create_plot(mydata, "api_temperature", "API Temperature Over Time", "api_temperature_over_time.png", line_color = "green")

# # plot for API Humidity
# create_plot(mydata, "api_humidity", "API Humidity Over Time", "api_humidity_over_time.png", line_color = "purple")

# # plot for API Clouds
# create_plot(mydata, "api_clouds", "API Clouds Over Time", "api_clouds_over_time.png", line_color = "orange")

# # plot for API Windspeed
# create_plot(mydata, "api_windspeed", "API Windspeed Over Time", "api_windspeed_over_time.png", line_color = "brown")



