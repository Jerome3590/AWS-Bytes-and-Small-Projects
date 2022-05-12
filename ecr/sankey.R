library(magrittr)
library(tidyverse)
library(readr)
library(networkD3)
library(caret)
library(htmlwidgets)
library(aws.s3)
library(jsonlite)

 args = commandArgs(trailingOnly = TRUE)
 EVENT_DATA <- args[1]
 REQUEST_ID <- args[2]

setwd("/tmp/")


s3sync(
  path = "/tmp/sankey",
  bucket = "sankey-data-vcu",
  prefix = "",
  direction = "download",
  verbose = FALSE,
  create = FALSE
)


# Data
tern1 <- read_csv("/tmp/sankey/Tern1.csv")

preprocessParams <- preProcess(as_tibble(tern1$Age), method=c("range"))

# summarize transform parameters
print(preprocessParams)

# transform the dataset using the parameters
transformed <- predict(preprocessParams, as_tibble(tern1$Age))



# Sankey Chart
nodes_prep <- tern1$Age %>% unique() %>% sort() %>% as.character() 
nodes_prep[12] <- c("Returned ")
nodes_prep[13] <- c("Did Not Return ")

nodes_df <- as_tibble(nodes_prep)
names(nodes_df) <- "Nodes"


nodes_df$group <-nodes_df$Nodes
# c("1","2","3","4","5","6","7","8","9","10","11","Returned ","Did Not Return ")
names(nodes_df)[2] <- "group"


nodes <- data.frame(
  name = nodes_df$Nodes %>% sort(),
  group <- nodes_df$group
)

# Bird  "Did Not Return" // "Returned"
tern1$Class <-  ifelse(tern1$Return == 1, "Returned ", "Did Not Return ") 
tern1$Value <-  ifelse(tern1$Return == 1, 1, 1)

links  <- data.frame(
  
  source  = tern1$Age %>% sort() %>% as.character(),
  target =  tern1$Class %>% as.character(),
  value = tern1$Value
)


links$source <- match(links$source, nodes$name) - 1
links$target <- match(links$target, nodes$name) - 1
names(nodes)[2] <- "group"


sankey  <- sankeyNetwork(Links = links, Nodes = nodes, Source = "source", 
                         Target = "target", Value = "value", NodeID = "name", iterations = 0,
                         units = "Birds", NodeGroup = "group", fontSize = 12, nodeWidth = 30)

sankey <- htmlwidgets::prependContent(sankey, htmltools::tags$h1("Tern Age Vs Return|Not Return", style = "color:blue"))


saveWidget(sankey, file=paste0( getwd(), "/sankey/sankeyDiagram.html"))


s3sync(
  path = "/tmp/sankey",
  bucket = "vcu-stat-591-sankey",
  prefix = "",
  direction = "upload",
  verbose = FALSE,
  create = FALSE
)

