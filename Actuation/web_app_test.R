# # set working directory
# setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(shiny)
library(httr)
library(jsonlite)
library(ggplot2)
library(lubridate)
library(DT)
library(plotly)
library(corrplot)
library(forecast)

# define base urls (both for thingspeak, but different channels)
thingspeak_base_url <- "https://api.thingspeak.com/channels/2722292/feeds.json?api_key=4361LIQAX967U4LR"
openweather_base_url <- "https://api.thingspeak.com/channels/2722321/feeds.json?api_key=MNH3AW0JYV8RBDN1"

# read the new csv with linearly interpolated values
mydata <- read.csv("final_data_readings_updated.csv", header = TRUE)

# function to fetch the stored data from thingspeak
fetch_thingspeak_data <- function(api_url) {
  response <- GET(api_url)
  if (response$status_code == 200) {
    content <- fromJSON(content(response, as = "text"), flatten = TRUE)
    return(content$feeds)
  } else {
    stop("Failed to fetch data: ", response$status_code)
  }
}



################################# UI code ######################################

ui <- fluidPage(
  # navigation bars
  navbarPage(
    "Smart Tortoise Enclosure Tracking System",
    
    # overview tab UI
    tabPanel(
      "Overview",
      fluidPage(
        tags$head(
          tags$style(HTML("
        .tabler-container .card {
          border-radius: 5px;
          box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.1);
          border: 1px solid #ddd;
          text-align: center;
          padding: 15px;
          margin-bottom: 15px;
          background-color: #ffffff;
        }
        .tabler-container h3 {
          font-size: 28px;
          font-weight: 600;
          color: #333333;
          margin-bottom: 10px;
        }
        .tabler-container h2 {
          font-size: 32px;
          font-weight: 500; /* Slightly less bold */
          color: #555555;
          margin: 0;
        }
        .tabler-container h4 {
          font-size: 14px;
          font-weight: normal;
          color: #888888;
          margin-top: 5px;
        }
        .profile-card {
          background: linear-gradient(to bottom, #eaf6ff, #ffffff);
          border-radius: 10px;
          padding: 20px;
          text-align: center;
          box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.1);
        }
        .profile-card img {
          width: 100px;
          height: 100px;
          border-radius: 50%;
          border: 3px solid #ffffff;
          background-color: #ddd;
          margin-top: -50px; /* Overlap the top section */
          position: relative;
          box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2);
        }
        .profile-card h3 {
          font-size: 24px;
          font-weight: bold;
          color: #333333;
          margin: 10px 0 5px 0;
        }
        .profile-card p {
          font-size: 14px;
          color: #666666;
          margin: 5px 0 15px 0;
        }
        .tag {
          display: inline-block;
          background-color: #e0e0e0;
          color: #555555;
          font-size: 12px;
          padding: 5px 10px;
          border-radius: 15px;
          margin: 2px;
        }
        .tag.green {
          background-color: #8bc34a;
          color: white;
        }
        .icons {
          font-size: 18px;
          color: #888888;
          margin: 5px 10px;
        }
        .overview-box {
          background-color: #f9f9f9;
          border-radius: 10px;
          padding: 20px;
          text-align: center;
          box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.1);
          margin-bottom: 15px;
        }
        .overview-box p {
          font-size: 14px;
          color: #666666;
        }
        .stat-box {
          border-radius: 5px;
          box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.1);
          border: 1px solid #ddd;
          text-align: center;
          padding: 15px;
          background-color: #ffffff;
          margin-bottom: 15px;
        }
        .stat-box h2 {
          font-size: 32px;
          font-weight: 500;
          color: #555555;
          margin: 0;
        }
        .stat-box h4 {
          font-size: 14px;
          color: #888888;
          margin-top: 5px;
        }
        .placeholder-section {
          margin-top: 20px;
          text-align: center;
        }
        .placeholder-section img {
          width: 100%;
          height: auto;
          border-radius: 10px;
          box-shadow: 0px 4px 15px rgba(0, 0, 0, 0.1);
        }
      "))
        ),
        div(
          class = "tabler-container container mt-4",
          div(
            class = "row",
            # Profile section on the left
            div(
              class = "col-md-4",
              div(
                class = "profile-card",
                div(
                  style = "height: 100px; background-image: url('background.jpg'); background-size: cover; background-position: center; border-radius: 10px 10px 0 0; margin: -15px; padding: 0; width: calc(100% + 30px);"
                ),
                img(
                  src = "tortoise.jpg",  # Ensure the image is in the www folder
                  alt = "Tortoise Image",
                  style = "margin-top: -30px; border: 3px solid #fff; width: 75px; height: 75px; border-radius: 50%; box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.2);"
                ),
                h3("Mishell"),
                p("Mishell is a 4-month-old spur-thighed Greek tortoise with a knack for mischief and a love for naps. Beneath her calm exterior lies a strategist always plotting her next move!"),
                # Tags
                span(class = "tag", "escape artist"),
                span(class = "tag green", "bok choy enthusiast")
              )
            ),
        
            # overview box on the right
            div(
              class = "col-md-8",
              div(
                class = "overview-box",
                h3("Tortoise Dashboard"),
                p("This app monitors the humidity and temperature of Mishell's indoor enclosure in real-time and compares it with outdoor conditions using data from the OpenWeather API. It includes a Pearson correlation graph, a timescale slider for analysing raw sensor and weather data over time, and reminders to encourage my family to check on Mishell, our new tortoise, and raise awareness of her care.")
              ),
              # creating three boxes directly below the overview box
              div(
                class = "row mt-3",
                div(
                  class = "col-md-4",
                  div(
                    class = "stat-box",
                    h2(textOutput("current_temp")),
                    h4("Current Temp")
                  )
                ),
                div(
                  class = "col-md-4",
                  div(
                    class = "stat-box",
                    h2(textOutput("current_humidity")),
                    h4("Current Humidity")
                  )
                ),
                div(
                  class = "col-md-4",
                  div(
                    class = "stat-box",
                    h2("On"),
                    h4("Basking Bulb")
                  )
                )
              )
            )
          ),
          div(
            class = "tort_image",
            h3("Tortoise Moments"),
            img(
              src = "tort_edit2.jpg",
              alt = "Placeholder Collage"
            )
          )
        )
      )
    ),
    
    
    
    
    # 'DHT22 Data'tab
    tabPanel(
      "DHT22 Data",
      fluidPage(
        sliderInput("data_hours", 
                    "Select Hours of Data to View (DHT22 readings):", 
                    min = 1, max = 24, value = 6, step = 1,
                    width = "100%"),
        h3("DHT22 Sensor Readings"),
        fluidRow(
          column(6, plotlyOutput("humidity_plot", height = "400px")),
          column(6, plotlyOutput("temperature_plot", height = "400px"))
        ),
        h4("Latest DHT22 Data"),
        tableOutput("thingspeak_data_table")
      )
    ),
    
    # 'OpenWeather API Data' tab
    tabPanel(
      "OpenWeather API Data",
      fluidPage(
        sliderInput("weather_hours", 
                    "Select Hours of Data to View (OpenWeather API Data):", 
                    min = 1, max = 24, value = 3, step = 1,
                    width = "100%"),
        h3("OpenWeather API Data"),
        fluidRow(
          column(3, plotlyOutput("weather_temperature_plot", height = "300px")),
          column(3, plotlyOutput("weather_humidity_plot", height = "300px")),
          column(3, plotlyOutput("weather_clouds_plot", height = "300px")),
          column(3, plotlyOutput("weather_wind_speed_plot", height = "300px"))
        ),
        h4("Latest OpenWeather Data"),
        tableOutput("openweather_data_table")
      )
    ),
    
    # 'Correlation' tab
    tabPanel(
      "Correlation",
      h3("Correlation between Indoor and Outdoor Data"),
      fluidPage(
        plotOutput("correlation_plot", height = "600px"),  # Correlation plot output
        p("This correlation plot compares sensor readings with weather data using the Pearson Correlation.")
      )
    ),
    
    tabPanel(
      "Forecasting",
      fluidPage(
        h3("Humidity Forecast for the Next 24 Hours"),
        plotOutput("forecast_plot", height = "400px"),  # add forecast plot
        p("This tab displays the forecasted humidity levels for the next 24 hours. The red zone highlights critical levels below 40% where urgent action is needed. Please note that the forecasted plot will be run and generated everyday at midnight!")
      )
    ),
    
    # 'Help Mishell' tab
    tabPanel(
      "Help Mishell", 
      fluidPage(
        h3("Help Mishell Notifications"),
        fluidRow(
          column(
            4,
            div(
              style = "text-align: center; display: flex; flex-direction: column; align-items: center;",
              img(
                src = "feed_mishell.jpg",
                alt = "Feed Icon",
                style = "width: 250px; height: 250px; margin-bottom: 10px;"
              ),
              actionButton("btn_feed", "Feed Mishell :)")
            )
          ),
          column(
            4,
            div(
              style = "text-align: center; display: flex; flex-direction: column; align-items: center;",
              img(
                src = "mist_enclosure.jpg",
                alt = "Temperature Icon",
                style = "width: 250px; height: 250px; margin-bottom: 10px;"
              ),
              actionButton("btn_humidity", "Mist Enclosure!!")
            )
          ),
          column(
            4,
            div(
              style = "text-align: center; display: flex; flex-direction: column; align-items: center;",
              img(
                src = "upside_down.jpg",
                alt = "Humidity Icon",
                style = "width: 250px; height: 250px; margin-bottom: 10px;"
              ),
              actionButton("btn_upside_down", "Mishell is upside down again...")
            )
          )
        ),
        verbatimTextOutput("notification_status"),
        # gif
        div(
          uiOutput("temp_gif"),
          style = "margin-top: 20px; text-align: center;"
        )
      )
    )
  )
)



################################# server code ######################################

server <- function(input, output, session) {
  # extracting thr latest temperature and humidity values
  latest_thingspeak_values <- reactive({
    data <- thingspeak_data()
    if (!is.null(data) && nrow(data) > 0) {
      latest_entry <- tail(data, 1)
      list(
        temperature = as.numeric(latest_entry$field2),  # temperature (field2)
        humidity = as.numeric(latest_entry$field1)      # humidity (field1)
      )
    } else {
      list(temperature = NA, humidity = NA)
    }
  })
  
  # update 'Overview tab' the "Current Temp" and "Current Humidity" boxes
  output$current_temp <- renderText({
    paste0(latest_thingspeak_values()$temperature, "°C")
  })
  output$current_humidity <- renderText({
    paste0(latest_thingspeak_values()$humidity, "%")
  })
  

  # function to perform forecasting and return the forecast data
  perform_forecasting <- function() {
    # fetching the last 24 hours of temperature data from thingspeak to use as exogeneous variable
    temperature_data <- fetch_thingspeak_data(paste0(thingspeak_base_url, "&results=288"))
    last_24_hours_temperature <- as.numeric(temperature_data$field2)
    
    # ensure valid temperature data
    if (any(is.na(last_24_hours_temperature))) {
      message("Invalid temperature data received. Skipping forecasting.")
      return(NULL)
    }
    
    # assigning training data
    split_point <- floor(0.7 * nrow(mydata))
    train_data <- mydata[1:split_point, ]
    
    # fitting the ARIMAX model with optimal parameters 
    fit <- auto.arima(train_data$humidity, xreg = train_data$temperature)
    
    # performing the forecast next 24 hours
    forecast_next_24 <- forecast(
      fit,
      xreg = matrix(last_24_hours_temperature, ncol = 1),
      h = 288
    )
    
    # create a dataframe for forecasted values
    forecast_24_df <- data.frame(
      Time = seq(from = Sys.time(), by = "5 min", length.out = 288),
      Forecast = as.numeric(forecast_next_24$mean),
      Lower80 = as.numeric(forecast_next_24$lower[, 1]),
      Upper80 = as.numeric(forecast_next_24$upper[, 1])
    )
    
    # send whatsapp notification if any values fall below the threshold
    if (any(forecast_24_df$Forecast < 40)) {
      warning_message <- "ALERT: Forecasted humidity levels will drop below 40%! Take action now."
      send_whatsapp_message("+447856787414", "5510890", warning_message)
    } else {
      message("No critical conditions in forecast.")
    }
    
    return(forecast_24_df)
  }
  
  # reactive for storing forecast results
  forecast_data <- reactiveVal(NULL)
  
  # scheduling the task to run forecasting everyday at 00:00
  observe({
    invalidateLater(60000, session)  # check every 60 seconds
    current_time <- format(Sys.time(), "%H:%M")
    if (current_time == "00:00") {
      forecast_data(perform_forecasting())  # store forecast results in reactiveVal
    }
  })
  
  # render the forecast plot in the 'Forecasting' tab
  output$forecast_plot <- renderPlot({
    forecast_result <- forecast_data()
    if (is.null(forecast_result)) {
      return(NULL)
    }
    ggplot(forecast_result, aes(x = Time, y = Forecast)) +
      geom_line(color = "blue", size = 1) +                 # blue is the forecast line
      # adding red zone for humidity < 40% 
      geom_rect(data = data.frame(xmin = min(forecast_result$Time), 
                                  xmax = max(forecast_result$Time), 
                                  ymin = -Inf, ymax = 40),
                aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
                fill = "red", alpha = 0.1, inherit.aes = FALSE) +
      labs(
        title = "Forecasted Humidity for the Next 24 Hours",
        x = "Time",
        y = "Humidity (%)"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 0, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
      )
    
    
    
  })
  

  # reactive urls for fetching data for updaing the DHT22 and OpenWeather graphs
  reactive_thingspeak_url <- reactive({
    num_results <- input$data_hours * 12  # 12 results per hour thingspeak updates every 5 mins)
    paste0(thingspeak_base_url, "&results=", num_results)
  })
  reactive_openweather_url <- reactive({
    num_results <- input$weather_hours * 6  # 6 results per hour (OpenWeather updates every 10 mins)
    paste0(openweather_base_url, "&results=", num_results)
  })
  
  # reactive polling for thingspeak humidity and temperature data
  thingspeak_data <- reactivePoll(
    intervalMillis = 5000,
    session = session,
    checkFunc = function() {
      new_data <- fetch_thingspeak_data(reactive_thingspeak_url())
      return(tail(new_data$entry_id, 1)) 
    },
    valueFunc = function() {
      fetch_thingspeak_data(reactive_thingspeak_url())
    }
  )
  
  # reactive polling for OpenWeather data
  openweather_data <- reactivePoll(
    intervalMillis = 5000,
    session = session,
    checkFunc = function() {
      new_data <- fetch_thingspeak_data(reactive_openweather_url())
      return(tail(new_data$entry_id, 1))
    },
    valueFunc = function() {
      fetch_thingspeak_data(reactive_openweather_url())
    }
  )
  
  # DHT22: humidity plot
  output$humidity_plot <- renderPlotly({
    data <- thingspeak_data()
    data$created_at <- as.POSIXct(data$created_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    plot_ly(data, x = ~created_at, y = ~as.numeric(field1), type = 'scatter', mode = 'lines+markers',
            line = list(color = 'blue'), marker = list(color = 'blue')) %>%
      layout(title = "Humidity", xaxis = list(title = "Time"), yaxis = list(title = "Humidity (%)"))
  })
  
  # DHT22: temperature plot
  output$temperature_plot <- renderPlotly({
    data <- thingspeak_data()
    data$created_at <- as.POSIXct(data$created_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    plot_ly(data, x = ~created_at, y = ~as.numeric(field2), type = 'scatter', mode = 'lines+markers',
            line = list(color = 'red'), marker = list(color = 'red')) %>%
      layout(title = "Temperature", xaxis = list(title = "Time"), yaxis = list(title = "Temperature (°C)"))
  })
  
  # OpenWeather: temperature plot
  output$weather_temperature_plot <- renderPlotly({
    data <- openweather_data()
    data$created_at <- as.POSIXct(data$created_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    plot_ly(data, x = ~created_at, y = ~as.numeric(field1), type = 'scatter', mode = 'lines+markers',
            line = list(color = 'gray'), marker = list(color = 'gray')) %>%
      layout(title = "Temperature", xaxis = list(title = "Time"), yaxis = list(title = "Temperature (°C)"))
  })
  
  # OpenWeather: humidity plot
  output$weather_humidity_plot <- renderPlotly({
    data <- openweather_data()
    data$created_at <- as.POSIXct(data$created_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    plot_ly(data, x = ~created_at, y = ~as.numeric(field2), type = 'scatter', mode = 'lines+markers',
            line = list(color = 'green'), marker = list(color = 'green')) %>%
      layout(title = "Humidity", xaxis = list(title = "Time"), yaxis = list(title = "Humidity (%)"))
  })
  
  # OpenWeather: clouds plot
  output$weather_clouds_plot <- renderPlotly({
    data <- openweather_data()
    data$created_at <- as.POSIXct(data$created_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    plot_ly(data, x = ~created_at, y = ~as.numeric(field3), type = 'scatter', mode = 'lines+markers',
            line = list(color = 'darkred'), marker = list(color = 'darkred')) %>%
      layout(title = "Cloud Coverage", xaxis = list(title = "Time"), yaxis = list(title = "Cloud Coverage (%)"))
  })
  
  # OpenWeather: wind speed plot
  output$weather_wind_speed_plot <- renderPlotly({
    data <- openweather_data()
    data$created_at <- as.POSIXct(data$created_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    plot_ly(data, x = ~created_at, y = ~as.numeric(field4), type = 'scatter', mode = 'lines+markers',
            line = list(color = 'orange'), marker = list(color = 'orange')) %>%
      layout(title = "Wind Speed", xaxis = list(title = "Time"), yaxis = list(title = "Wind Speed (m/s)"))
  })
  
  # DHT22: latest data table (display last 2 entries for checking if graph is correct)
  output$thingspeak_data_table <- renderTable({
    data <- thingspeak_data()
    tail(data[, c("created_at", "field1", "field2")], 2) %>%
      rename("Timestamp" = created_at, 
             "Humidity (%)" = field1,
             "Temperature (°C)" = field2)
  })
  
  # OpenWeather: latest data table (display last 2 entries for checking if graph is correct)
  output$openweather_data_table <- renderTable({
    data <- openweather_data()
    tail(data[, c("created_at", "field1", "field2", "field3", "field4")], 2) %>%
      rename("Timestamp" = created_at, 
             "Temperature (°C)" = field1,
             "Humidity (%)" = field2,
             "Cloud Coverage (%)" = field3,
             "Wind Speed (m/s)" = field4)
  })
  
  ########################## pearson_correlation.R #############################
  
  # select only the numeric columns for correlation analysis
  numeric_data <- mydata[, c("humidity", "temperature", "api_temperature", "api_humidity", "api_clouds", "api_windspeed")]
  
  # Calculate the Pearson correlation matrix
  cor_matrix <- cor(numeric_data, method = "pearson")
  
  # render the correlation plot
  output$correlation_plot <- renderPlot({
    corrplot(cor_matrix, 
             method = "color",       # Use color-filled squares
             type = "full",          # Show full matrix (both upper and lower)
             tl.col = "black",       # Color of the text labels
             tl.srt = 45,            # Rotate the text labels for better readability
             tl.cex = 0.8,           # Reduce the font size of the text labels
             addCoef.col = rgb(0, 0, 0, 0.5),  # Set text color to black with 30% opacity for subtlety
             number.cex = 0.7,       # Reduce the font size of the numbers
             diag = FALSE,           # Option to remove the diagonal (1s)
             col = colorRampPalette(c("#87CEEB", "white", "lightgreen"))(200))
  })
  
  
  ########################## actuation_message.R ###############################
  
  # 'Help Mishell' tab whatsapp notification 
  observeEvent(input$btn_feed, {
    message <- "Reminder: Time to feed Mishell!"
    send_whatsapp_message("+447856787414", "5510890", message)
    # send_whatsapp_message("+447856787414", "5510890", "Reminder: Time to feed Mishell!")
    # Display GIF
    output$temp_gif <- renderUI({
      tags$img(
        src = "https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExb2xwbDJpcm4yYzNvejh0dXFlZGhuN2d3cjZiOWtyenoxdnBtYWRiaSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/IbAJCkl4NUaYEfPEzm/giphy.gif",
        style = "width: 300px; height: auto;"
      )
    })
  })

  observeEvent(input$btn_humidity, {
    send_whatsapp_message("+447856787414", "5510890", "Humidity Alert: Please check Mishell's enclosure humidity!")
    # Display GIF
    output$temp_gif <- renderUI({
      tags$img(
        src = "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExamd6MGU1eTZlNzBrZ3ZxZmZncjF2ZXRzNGtzcDJtOWNnY3NieTNweSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/ar3EvPXGul6i9PRLos/giphy.gif",
        style = "width: 300px; height: auto;"
      )
    })
  })
  
  observeEvent(input$btn_upside_down, {
    send_whatsapp_message("+447856787414", "5510890", "EMERGENCY: Check if Mishell is upside down again...")
    output$temp_gif <- renderUI({
      tags$img(
        src = "https://i.giphy.com/media/v1.Y2lkPTc5MGI3NjExeWc2MXM4dDk0NmU3NG5jNjVqa2hnaWJyMzNkM3R4bmZoOXA2enJ4OCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0Extn1wgzXyZn0J2/giphy.gif",
        style = "width: 300px; height: auto;"
      )
    })
  })

  
  # function to send message
  send_whatsapp_message <- function(phone_number, api_key, message) {
    encoded_message <- URLencode(message)
    
    # construct the API url
    api_url <- paste0(
      "https://api.callmebot.com/whatsapp.php?",
      "phone=", phone_number,
      "&text=", encoded_message,
      "&apikey=", api_key
    )
    
    # making the GET request
    response <- tryCatch({
      GET(api_url)
    }, error = function(e) {
      NULL
    })
    
    # check the response
    if (!is.null(response) && status_code(response) == 200) {
      output$notification_status <- renderText(paste("Message sent successfully: ", message))
    } else {
      output$notification_status <- renderText("Failed to send the message. Please check your API details.")
    }
  }
}

# Run the app
shinyApp(ui, server)
