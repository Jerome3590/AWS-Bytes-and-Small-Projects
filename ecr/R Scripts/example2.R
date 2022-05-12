#!/var/task/R/bin/Rscript

library(lubridate)
library(dplyr)
library(tidyr)
library(magrittr)
library(data.table)
library(reshape2)
library(jsonlite)

args = commandArgs(trailingOnly = TRUE)
 
FUNCTION <- args[1]
EVENT_DATA <- args[2]
REQUEST_ID <- args[3]


handler <- function(EVENT_DATA) {


 values <- fromJSON(EVENT_DATA) %>% as.data.frame()

 # Number of Scouts
 point1 <- as.numeric(values$Troop1)
 point2 <- as.numeric(values$Troop2)
 point3 <- as.numeric(values$Troop2)


 pos <- c(point1, point2, point3)
 pos_df <- as.data.frame(pos)

 # Days of Supply
 dos1 <- as.numeric(values$DOS1)
 dos2 <- as.numeric(values$DOS2)
 dos3 <- as.numeric(values$DOS3)
 dos4 <- as.numeric(values$DOS4)


 dos <- c(dos1, dos2, dos3, dos4)
 dos_df <- as.data.frame(dos)

 unit <- c("Webelos")
 feed_plan <- 4
 final_location <- c("Camp Washington")


 start_date <- as.Date(mdy_hms("4/12/2021 12:00:00 AM"))
 start_date2 <- start_date + dos1 + 1
 start_date3 <- start_date2 + dos2 + 1
 start_date4 <- start_date3 + dos3 + 1


 dos1_df <- as.data.frame(dos_df[1,])

 DOS1_df <- dos1_df %>%
  mutate(Date = start_date) %>%
  complete(Date = seq.Date(start_date, (start_date + dos1), by="day"), dos1_df) %>%
  mutate(Scout_Numbers = pos[1]) %>%
  mutate(Feed_Plan = feed_plan) %>%
  mutate(Unit = unit) %>%
  mutate(`Final Campsite Location` = final_location)


 names(DOS1_df)[2] <- "DOS"


 dos2_df <- as.data.frame(dos_df[2,])

 DOS2_df <- dos2_df %>%
  mutate(Date = as.Date(start_date2)) %>%
  complete(Date = seq.Date(start_date2, (start_date2 + dos2), by="day"), dos2_df) %>%
  mutate(Scout_Numbers = pos[1] + pos[2]) %>%
  mutate(Feed_Plan = feed_plan) %>%
  mutate(Unit = unit) %>%
  mutate(`Final Campsite Location` = final_location)

 names(DOS2_df)[2] <- "DOS"


 dos3_df <- as.data.frame(dos_df[3,])

 DOS3_df <- dos3_df %>%
  mutate(Date = as.Date(start_date3)) %>%
  complete(Date = seq.Date(start_date3, (start_date3 + dos3), by="day"), dos3_df) %>%
  mutate(Scout_Numbers = pos[1] + pos[2] + pos[3]) %>%
  mutate(Feed_Plan = feed_plan) %>%
  mutate(Unit = unit) %>%
  mutate(`Final Campsite Location` = final_location)

  names(DOS3_df)[2] <- "DOS"


 dos4_df <- as.data.frame(dos_df[4,])

 DOS4_df <- dos4_df %>%
  mutate(Date = as.Date(start_date4)) %>%
  complete(Date = seq.Date(start_date4, (start_date4 + dos4), by="day"), dos4_df) %>%
  mutate(Scout_Numbers = pos[1] + pos[2] + pos[3]) %>%
  mutate(Feed_Plan = feed_plan) %>%
  mutate(Unit = unit) %>%
  mutate(`Final Campsite Location` = final_location)

 names(DOS4_df)[2] <- "DOS"


 DOS1_df_updated <- DOS1_df %>%
  mutate(`MEALS READY TO EAT (MRE)` = case_when(
    feed_plan == 1 ~ pos[1] * 3,
    feed_plan == 2 ~ pos[1] * 2,
    feed_plan == 3 ~ pos[1] * .66,
    feed_plan == 4 ~ pos[1] * .47)
  ) %>% 
  
  mutate(`UGR(H&S)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] * 0,
    feed_plan == 2 ~ pos[1] * 0,
    feed_plan == 3 ~ pos[1] * 0,
    feed_plan == 4 ~ pos[1] * .2)
  ) %>% 
  
  mutate(`UGR(H&S)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] * 0,
    feed_plan == 2 ~ pos[1] * 0,
    feed_plan == 3 ~ pos[1] * .33,
    feed_plan == 4 ~ pos[1] * 0)
  ) %>% 
  
  mutate(`UGR(M)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] * 0,
    feed_plan == 2 ~ pos[1] * .5,
    feed_plan == 3 ~ pos[1] * 1,
    feed_plan == 4 ~ pos[1] * .33)
  ) %>% 
  
  mutate(`UGR(M)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] * 0,
    feed_plan == 2 ~ pos[1] * 0,
    feed_plan == 3 ~ pos[1] * 0,
    feed_plan == 4 ~ pos[1] * .33)
  )


 DOS2_df_updated <- DOS2_df %>%
  mutate(`MEALS READY TO EAT (MRE)` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] * 3,
    feed_plan == 2 ~ pos[1] + pos[2] * 2,
    feed_plan == 3 ~ pos[1] + pos[2] * .66,
    feed_plan == 4 ~ pos[1] + pos[2] * .47)
  ) %>% 
  
  mutate(`UGR(H&S)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] * 0,
    feed_plan == 4 ~ pos[1] + pos[2] * .2)
  ) %>% 
  
  mutate(`UGR(H&S)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] * .33,
    feed_plan == 4 ~ pos[1] + pos[2] * 0)
  ) %>% 
  
  mutate(`UGR(M)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] * .5,
    feed_plan == 3 ~ pos[1] + pos[2] * 1,
    feed_plan == 4 ~ pos[1] + pos[2] * .33)
  ) %>% 
  
  mutate(`UGR(M)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] * 0,
    feed_plan == 4 ~ pos[1] + pos[2] * .33)
  )


 DOS3_df_updated <- DOS3_df %>%
  mutate(`MEALS READY TO EAT (MRE)` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 3,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 2,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * .66,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .47)
  ) %>% 
  
  mutate(`UGR(H&S)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .2)
  ) %>% 
  
  mutate(`UGR(H&S)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * .33,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * 0)
  ) %>% 
  
  mutate(`UGR(M)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * .5,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * 1,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .33)
  ) %>% 
  
  mutate(`UGR(M)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .33)
  )


 DOS4_df_updated <- DOS4_df %>%
  mutate(`MEALS READY TO EAT (MRE)` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 3,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 2,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * .66,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .47)
  ) %>% 
  
  mutate(`UGR(H&S)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .2)
  ) %>% 
  
  mutate(`UGR(H&S)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * .33,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * 0)
  ) %>% 
  
  mutate(`UGR(M)-BREAKFAST` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * .5,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * 1,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .33)
  ) %>% 
  
  mutate(`UGR(M)-LUNCH/DINNER` = case_when(
    feed_plan == 1 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 2 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 3 ~ pos[1] + pos[2] + pos[3] * 0,
    feed_plan == 4 ~ pos[1] + pos[2] + pos[3] * .33)
  )


 scoutflow_df <- rbindlist(list(DOS1_df_updated, DOS2_df_updated, DOS3_df_updated, DOS4_df_updated))

 print(tail(scoutflow_df, 20))
 print(values)
 print(str(values))
}


hello_world <- function(){
  print("Hello World!")

}

################################

handler()

hello_world()

