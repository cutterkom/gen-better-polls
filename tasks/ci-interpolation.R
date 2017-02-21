
interpolate_ci_values <- function(pollster, party){
  df_ci_working <- df_ci_lower %>%  arrange(partei, datum) %>% filter(institut == pollster, partei == party) %>% select(datum, partei, institut,ci_lower)  
  df_ci_working <- merge(df_datum, df_ci_working, by = "datum", all.x = TRUE)
  
  
  # df mit partei, datum, ein institut
  d <- df_ci_working %>% filter(!is.na(institut))
  d$datum <- as.Date(d$datum)
  
  get_missing_point <- function(date_young, date_older, date_missing, ci_younger, ci_older)
  {
    adjacent_side_current <- as.numeric(difftime(as.Date(date_young), as.Date(date_older), units = c("days")))
    adjacent_side_new <- as.numeric(difftime(as.Date(date_missing),as.Date(date_older), units = c("days")))
  
    ci_missing <- ci_older + ((ci_younger-ci_older)/adjacent_side_current)*adjacent_side_new
    return(ci_missing)
  }
  
  find_prev_date <- function (currentDate){
    index <- findInterval(as.Date(currentDate), d$datum)
    prevDate <- ifelse(index == 0, NA, as.character(d$datum[index]))
    as.character(prevDate)
  }
  
  find_next_date <- function (prevDate){
    index <- match(as.Date(prevDate), d$datum)
    nextDate <- d$datum[index+1]
    as.character(nextDate)
  }
  
  find_ci <- function (date){
    index <- match(as.Date(date), d$datum)
    ci <- ifelse(!is.na(index), d$ci_lower[index], NA)
  }
  
  prev_date <- apply(df_ci_working["datum"], 1, find_prev_date)
  df_ci_working$prev_date <- unlist(prev_date)
  
  next_date <- apply(df_ci_working["prev_date"], 1, find_next_date)
  df_ci_working$next_date <- unlist(next_date)
  
  prev_ci <- apply(df_ci_working["prev_date"], 1, find_ci)
  df_ci_working$prev_ci <- unlist(prev_ci)
  
  next_ci <- apply(df_ci_working["next_date"], 1, find_ci)
  df_ci_working$next_ci <- unlist(next_ci)
  
  df_interpolate <- df_ci_working
  
  for (ci in seq_along(df_interpolate$ci_lower)){
    if (is.na(df_interpolate$ci_lower[ci])) {
      df_interpolate$ci_lower[ci] <- get_missing_point(df_interpolate$next_date[ci], df_interpolate$prev_date[ci], df_interpolate$datum[ci], df_interpolate$next_ci[ci], df_interpolate$prev_ci[ci])
    }
  }
  df_interpolate <- select(df_interpolate, datum, ci_lower)
  return(df_interpolate)
}
df_new <- interpolate_ci_values("allens", "FDP")