# set working directory
setwd("C:\\Users\\jayde\\OneDrive - Imperial College London\\Year 4\\SIoT\\Data Analysis")

# load required libraries
library(corrplot)

# read the new csv with linearly interpolated values
mydata <- read.csv("final_data_readings_updated.csv", header = TRUE)

# select only the numeric columns for correlation analysis
numeric_data <- mydata[, c("humidity", "temperature", "api_temperature", "api_humidity", "api_clouds", "api_windspeed")]

# view the structure of the selected numeric data
str(numeric_data)

# calculate the Pearson correlation matrix
cor_matrix <- cor(numeric_data, method = "pearson")

# view the correlation matrix - this will plot onto the console
print(cor_matrix)

# visualise the correlation matrix using corrplot with a color-filled square layout
corrplot(cor_matrix, 
         method = "color",       
         type = "full",          
         tl.col = "black",       
         tl.srt = 45,            
         tl.cex = 0.8,           
         addCoef.col = rgb(0, 0, 0, 0.5), 
         number.cex = 0.7,       
         diag = FALSE,           
         col = colorRampPalette(c("#87CEEB", "white", "lightgreen"))(200))