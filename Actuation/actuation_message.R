# set working directory
setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(httr)
library(jsonlite)

# CallMeBot API details
phone_number <- "+447856787414" 
api_key <- "5510890"
message <- "Hello from R! Testing Testing 2 3."

# encode a string (the message) to handle special characters
encoded_message <- URLencode(message)

# constructing the API url
api_url <- paste0(
  "https://api.callmebot.com/whatsapp.php?",
  "phone=", phone_number,
  "&text=", encoded_message,
  "&apikey=", api_key
)

# making the GET request
response <- GET(api_url)

# check the response
if (status_code(response) == 200) {
  cat("Message sent successfully!\n")
  print(content(response, "text"))
} else {
  cat("Failed to send the message. Status code:", status_code(response), "\n")
  print(content(response, "text"))
}
