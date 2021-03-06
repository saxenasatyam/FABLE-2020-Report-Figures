# Figure 3: Historical values from the UNFCCC gas inventory
# Author: Clara Douzal (SDSN)
# Last update: 20201209


fct_Figure3 <- function(my_data, outpath, country){
  

# Handling data -----------------------------------------------------------
  
  conflict_prefer("lag", "dplyr")
  conflict_prefer("filter", "dplyr")
  
  
  my_data_full <- my_data
  if( length(which(my_data[,"Mt.CO2.equivalent"]== 0)>0)){
    my_data_full <- my_data <- droplevels(my_data[-which(my_data[,"Mt.CO2.equivalent"]== 0),])
  }
  #create dataframe for negative values
  if(length(which(my_data[,"Mt.CO2.equivalent"]<0))>0){
    my_data_neg <- my_data[which(my_data[,"Mt.CO2.equivalent"]<0),]
    my_data <- my_data[-which(my_data[,"Mt.CO2.equivalent"]<0),]
    my_data_neg$Amount <- -my_data_neg[,"Mt.CO2.equivalent"] / sum(my_data[,"Mt.CO2.equivalent"])#to have right unit"
    
  }
  
  #Data for the donut chart is percenatges
  my_data$Amount <- my_data[,"Mt.CO2.equivalent"] / sum(my_data[,"Mt.CO2.equivalent"])
  my_data <- my_data[order(my_data$Category),]
  
  #used to put the middle of the AFOLU segment at cos(x) = 1 and sin(x) = 0
  temp <- sum(my_data$Amount[which(my_data$Category == "AFOLU")])/2
  
  #Data used for the donut chart
  my_data_aug <- my_data %>%
    group_by(Category) %>% 
    summarise(Amount = sum(Amount)) %>%
    mutate(arc_start = cumsum(lag(Amount, default = 0)) * 2*pi + pi/2 -temp*2*pi, 
           arc_end   = cumsum(Amount) * 2*pi + pi/2 - temp*2*pi,
           x_pos = 0 + cos(arc_start - pi/2),
           y_pos = 1 - sin(arc_start - pi/2),
           middle = 0.5 * (arc_start + arc_end),
           hjust = ifelse(middle > pi, 1, 0),
           vjust = ifelse(middle < pi/2 | middle > 3 * pi/2, 0, 1))
  my_data_aug <- data.frame(my_data_aug)
  
  #data used for the emissions bar chart from AFOLU
  my_data_detail <- my_data %>%
    filter(Category == "AFOLU") %>%
    arrange(`Sub.Category`) %>%
    purrr::map_df(rev) %>%    # This reverses the order
    mutate(Amount_scaled = Amount / sum(Amount) * 2) %>% 
    data.frame()
  my_data_detail <- my_data_detail %>% 
    group_by(Sub.Category) %>% 
    mutate(Amount_scaled = sum(Amount_scaled, na.rm = T),
           Amount = sum(Amount, na.rm = T),
           Mt.CO2.equivalent = sum(Mt.CO2.equivalent, na.rm = T)) %>% 
    select(Category, Sub.Category, Mt.CO2.equivalent, Amount, Amount_scaled) %>% 
    unique() %>% 
    data.frame()
  
  
  if(exists("my_data_neg")){
    #data used for the removals bar chart from AFOLU
    my_data_detail_neg <- my_data_neg %>%
      filter(Category == "AFOLU") %>%
      arrange(`Sub.Category`) %>%
      purrr::map_df(rev) %>%    # This reverses the order
      mutate(Amount_scaled = Amount / sum(my_data$Amount[which(my_data$Category == "AFOLU")]) * 2) %>% 
      data.frame()
    
    my_data_detail_neg <- my_data_detail_neg %>% 
      group_by(Sub.Category) %>% 
      mutate(Amount_scaled = sum(Amount_scaled, na.rm = T),
             Amount = sum(Amount, na.rm = T),
             Mt.CO2.equivalent = sum(Mt.CO2.equivalent, na.rm = T)) %>% 
      select(Category, Sub.Category, Mt.CO2.equivalent, Amount, Amount_scaled) %>% 
      unique() %>% 
      data.frame()
  }
  
  #the lines going from extremities of the AFOLU segment in the donut to the extremities of the emissions from AFOLU bar chart
  my_data_lines <- my_data_aug %>%
    filter(Category == "AFOLU" | lag(Category == "AFOLU")) %>%
    slice(1, n())
  
  if(my_data_lines$x_pos[1]<0){
    my_data_lines$x_pos <- c(0,0)
    my_data_lines$y_pos <- c(2,0)
  }
  
  
# Total Emissions displayed in the middle of the donut
  
  tot_Emission_All <- TeX(paste0(round(sum(my_data[,"Mt.CO2.equivalent"])), 'MtCO$_{',2,'}e'), output = "character")
  
  
# Building the legend  -----------------------------------
  
  #keeping only the necessary categories for your country
  myColors_GHG_AFOLU <- myColors_GHG_AFOLU[my_data_aug$Category]
  
  p <- ggplot(my_data_aug)
  
  data_bar_emission <- my_data_detail %>% 
    mutate(percent = Amount_scaled/2) %>% 
    slice(which(percent>0.01)) %>% 
    droplevels() %>% 
    data.frame()
  
  
  text_donut <- c("AFOLU" = "white",
                  "Waste" = "black",
                  "Energy" = "black",
                  "IPPU"= "black",
                  "Other" = "black")
  
  if(country != "Colombia"){#colour palettes for countries that are not Colombia
  
  myColors_AFOLU <- c("Enteric Fermentation" = "#D1492C",
                      "Manure Management" = "#E18248",
                      "Rice Cultivation" = "#F0BA63",
                      "Agricultural Soils" = "#C21111",
                      "Other (Agriculture)" = "#FFF27E",
                      "Grassland" = "#c6e065",
                      "CO2 Emissions and Removals from Soil"= "#76c4c4" ,
                      "Harvested Wood Products" = "#734339",
                      "Cropland" = "#96325f",
                      "Wetlands" = "#bf2cac",
                      "Forest and Grassland Conversion" = "#143b13",
                      "Settlements" = "#9ea39e",
                      "Forest Land" = "#147314",
                      "Changes in Forest and Other Woody Biomass Stocks" = "#d65a62",
                      "Abandonment of Managed Lands" = "#2563ba",
                      "Other (Forest & LUC)" = "#83a1cc",
                      "Land-Use Change and Forestry" = "#61543f")
  
  myColors_text <- c("Enteric Fermentation" = "white",
                     "Manure Management" = "black",
                     "Rice Cultivation" = "black",
                     "Agricultural Soils" = "white",
                     "Other (Agriculture)" = "black",
                     "Grassland" = "black",
                     "CO2 Emissions and Removals from Soil"= "black" ,
                     "Harvested Wood Products" = "white",
                     "Cropland" = "white",
                     "Wetlands" = "white",
                     "Forest and Grassland Conversion" = "white",
                     "Settlements" = "black",
                     "Forest Land" = "white",
                     "Changes in Forest and Other Woody Biomass Stocks" = "white",
                     "Abandonment of Managed Lands" = "white",
                     "Other (Forest & LUC)" = "black",
                     "Land-Use Change and Forestry" = "white")
  
  order_emissions = c("Agricultural Soils",
                      "Enteric Fermentation",
                      "Manure Management",
                      "Rice Cultivation",
                      "Other (Agriculture)",
                      "CO2 Emissions and Removals from Soil" ,
                      "Grassland",
                      "Harvested Wood Products",
                      "Cropland",
                      "Forest and Grassland Conversion",
                      "Land-Use Change and Forestry",
                      "Settlements",
                      "Wetlands",
                      "Other (Forest & LUC)")
  
  order_removals = c("Abandonment of Managed Lands", 
                     "Changes in Forest and Other Woody Biomass Stocks",
                     "CO2 Emissions and Removals from Soil" ,
                     "Forest Land",
                     "Grassland",
                     "Harvested Wood Products",
                     "Land-Use Change and Forestry",
                     "Other (Forest & LUC)")
  }else{#colour palettes for Colombia
    
    myColors_AFOLU <- c("Enteric Fermentation" = "#D1492C",
                        "Manure Management" = "#E18248",
                        "Direct N2O Emissions from Managed Soils" = "#F0BA63",
                        "Biomass Burning, Indirect N2O Emissions from Managed Soils and Rice Crops" = "#B10026",
                        "Grassland" = "#c6e065",
                        "Cropland" = "#96325f",
                        "Wetlands, Settlements and Other Lands" = "#9ea39e",
                        "Forest Land" = "#147314")
    
    myColors_text <- c("Enteric Fermentation" = "white",
                       "Manure Management" = "white",
                       "Direct N2O Emissions from Managed Soils" = "white",
                       "Biomass Burning, Indirect N2O Emissions from Managed Soils and Rice Crops" = "white",
                       "Grassland" = "black",
                       "Cropland" = "white",
                       "Wetlands, Settlements and Other Lands" = "white",
                       "Forest Land" = "white")
    
    
    order_emissions = c("Biomass Burning, Indirect N2O Emissions from Managed Soils and Rice Crops",
                        "Enteric Fermentation",
                        "Manure Management",
                        "Direct N2O Emissions from Managed Soils",
                        "Cropland",
                        "Forest Land",
                        "Grassland",
                        "Wetlands, Settlements and Other Lands")
    
    order_removals = c("Cropland",
                       "Forest Land",
                       "Grassland")
    
  }
  
  #only keep the necessary sub categories for your country
  myColors_AFOLU <- myColors_AFOLU[unique(my_data_full[which(my_data_full$Category == "AFOLU"),"Sub.Category"])]
  myColors_AFOLU_legend_emissions <- myColors_AFOLU[unique(data_bar_emission$Sub.Category)]
  
  data_bar_emission <- data_bar_emission %>% 
    mutate(Sub.Category = factor(Sub.Category, levels = order_emissions)) %>% 
    droplevels()
  
  p_bar_emissions <- p + 
    geom_col(data = data_bar_emission, aes(x = `Sub.Category`, y = `Mt.CO2.equivalent`, fill = `Sub.Category`)) + 
    scale_fill_manual(name = "Source of AFOLU \nEmissions",
                      values = myColors_AFOLU,
                      labels = str_wrap(levels(data_bar_emission$Sub.Category),22)) + 
    theme(plot.margin = unit(c(-10, 0, -10, 0), "cm"),
          legend.spacing.x = unit(0.2, 'cm'),
          legend.text = element_text(size = 7.5/0.52),
          legend.title = element_text(size = 8/0.52))
  
  
  legend_emissions <- cowplot::get_legend(p_bar_emissions)
  
  if(exists("my_data_neg")){
    data_bar_emission_neg <- my_data_detail_neg %>% 
      mutate(percent = Amount_scaled/2) %>% 
      slice(which(percent>0.01)) %>% 
      droplevels() %>% 
      data.frame()
    
    myColors_AFOLU_legend_removals <- myColors_AFOLU[unique(data_bar_emission_neg$Sub.Category)]
    
    p_bar_removals <- p + geom_col(data = data_bar_emission_neg, aes(x = `Sub.Category`, y = `Mt.CO2.equivalent`, fill = `Sub.Category`)) + 
      scale_fill_manual(name = "Sink for AFOLU \nRemovals",
                        values = myColors_AFOLU,
                        labels = str_wrap(names(myColors_AFOLU_legend_removals)[order(names(myColors_AFOLU_legend_removals))],22)) + 
      theme(plot.margin = unit(c(-10, 0, -10, 0), "cm"),
            legend.spacing.x = unit(0.2, 'cm'),
            legend.text = element_text(size = 7.5/0.52),
            legend.title = element_text(size = 8/0.52))
    
    
    legend_removals <- cowplot::get_legend(p_bar_removals)
    
  }
  
  
  
  # Creation of plot to display ---------------------------------------------
  
  #If only emissions from AFOLU for your country
  
  p <- ggplot(my_data_aug)
  
  #Need to adjust the coordinates for the lines that link the donut to the bar chart depending on the country
  df_yend <- data.frame(Country = c("Australia", "Argentina", "Brazil", "Canada", "China", "Colombia", "Ethiopia",
                                    "Finland", "Germany", "India", "Indonesia", "Malaysia", "Mexico", "Norway", 
                                    "Russia", "Rwanda", "SouthAfrica", "Sweden", "UK", "USA"),
                        lines_right_top = rep(1.75, 20),
                        lines_right_bottom = rep(0.2, 20))
  
  placeholder_top <- 0
  placeholder_bottom <- 0
  
  if(country %in% c("Australia", "Canada", "China", "Colombia", 
                    "Finland", "Germany", "Indonesia", "Malaysia", "Norway", 
                    "Russia", "Rwanda", "SouthAfrica", "Sweden", "UK", "USA")){
  placeholder        <- (sum(my_data_detail_neg$Amount_scaled)- sum(my_data_detail$Amount_scaled))
  placeholder_top    <- (placeholder + sum(my_data_detail$Amount_scaled))/sum(my_data_detail_neg$Amount_scaled)
  placeholder_bottom <- (placeholder/sum(my_data_detail_neg$Amount_scaled)) }
  
  df_yend <- df_yend %>% 
    #change the y coordinate for the top right end of the segment that links the donut with the bar chart
    mutate(lines_right_top = ifelse(Country == "UK",
                                    1.75,
                                    ifelse(Country == "Rwanda",
                                           0.4 + placeholder_top,
                                           ifelse(Country == "Finland",
                                                  0.35 + placeholder_top,
                                                  ifelse(Country %in% c("Sweden", "Norway", "Russia"),
                                                         0.2 + placeholder_top,
                                                         ifelse(Country == "USA",
                                                                0.5 + placeholder_top,
                                                                ifelse(Country == "Malaysia",
                                                                       0.05 + placeholder_top,
                                                                       ifelse(Country %in% c("Argentina", "Brazil", "Ethiopia",
                                                                                             "India", "Mexico"),
                                                                              2,
                                                                              lines_right_top)))))))) %>% 
    #change the y coordinate for the bottom right end of the segment that links the donut with the bar chart
    mutate(lines_right_bottom = ifelse(Country %in% c("Finland", "Malaysia", "Norway", 
                                                      "Russia", "Rwanda", "Sweden", "USA"),
                                       placeholder_bottom,
                                       ifelse(Country %in% c("Argentina", "Brazil", "Ethiopia",
                                                             "India", "Mexico"),
                                              0,
                                              lines_right_bottom)))
  #keep only the data for the country we are currently plotting
  df_yend <- df_yend %>% 
    slice(which(Country == country))
  #Need to adjust the y coordinates of the text in the donut
  df_y_textdonut <- data.frame(Country = c("Australia", "Argentina", "Brazil", "Canada", "China", "Colombia", "Ethiopia",
                                           "Finland", "Germany", "India", "Indonesia", "Malaysia", "Mexico", "Norway", 
                                           "Russia", "Rwanda", "SouthAfrica", "Sweden", "UK", "USA"),
                               AFOLU_t = rep(0, 20),
                               Waste_t = rep(0, 20),
                               Energy_t = rep(0, 20),
                               IPPU_t = rep(0, 20))
  
  df_y_textdonut <- df_y_textdonut %>% 
    mutate(AFOLU_t = ifelse(country == "Malaysia",
                            -0.035,
                            AFOLU_t)) %>% 
    mutate(Waste_t = ifelse(country %in% c("Russia", "Germany"),
                                   -0.05,
                                   ifelse(country == "China",
                                          -0.085,
                                          ifelse(country %in% c("Rwanda", "USA"),
                                                 -0.1,
                                                 Waste_t)))) %>% 
    mutate(IPPU_t = ifelse( country %in% c("Rwanda", "Malaysia", "USA"),
                                   0.05,
                                   IPPU_t))
  #keep only the data for the country we are currently plotting
  df_y_textdonut <- df_y_textdonut %>% 
    slice(which(Country == country))
  
  #plot the donut of all sectors net emissions
  p_donut <- p + geom_arc_bar(aes(x0 = 0, y0 = 1,  
                                  r0 = 0.52, r  = 1,
                                  fill = Category,
                                  start = arc_start,
                                  end   = arc_end), color = NA, data = my_data_aug, show.legend = F) +
    scale_fill_manual(name = "Source of Emissions", 
                      values = myColors_GHG_AFOLU)+
    geom_text(aes(x = 0.75*sin(middle), 
                  y = 1+ 0.75*cos(middle) + c(df_y_textdonut$AFOLU_t, df_y_textdonut$Waste_t, df_y_textdonut$Energy_t, df_y_textdonut$IPPU_t),
                  label = paste0(Category, "\n", round(Amount* 100, 1), "%"),
                  color = Category),
              size = 3.9,
              show.legend = F)+
    scale_color_manual(values = text_donut)+
    annotate("segment", 
             x = my_data_lines[1:2, "x_pos"] +ifelse(country == "Rwanda", 0.25, 0),
             y = my_data_lines[1:2, "y_pos"],
             xend = 1.5,
             yend = c(df_yend$lines_right_top,
                      df_yend$lines_right_bottom)) + 
    annotate("text", x = 0, y = 1, label = tot_Emission_All, size = 4.9, parse = TRUE)+
    coord_equal() +
    theme(plot.margin = unit(c(-2, -2, -2, -2), "cm"))+
    theme_void()+
    theme(plot.background = element_rect(fill = "White"))
  
  my_data_detail$Sub.Category <- factor(my_data_detail$Sub.Category,
                                        levels = order_emissions)
  my_data_detail <- my_data_detail[rev(order(my_data_detail$Sub.Category)),]
  
  my_data_detail <- my_data_detail %>% 
    mutate(label = ifelse(Amount_scaled/sum(Amount_scaled)>0.13, 
                          TeX(paste0(round(Mt.CO2.equivalent,0), "MtCO$_{",2,"}e"), output = "character"), 
                          NA)) %>%
    data.frame()
  #plot the bar chart for emisions from AFOLU
  p_bar <- p + geom_tile(data = my_data_detail,
                         aes(x = 1, 
                             y = cumsum(Amount_scaled) - Amount_scaled/2,
                             height = Amount_scaled, fill = Sub.Category),
                         show.legend = F,
                         color = "white") +
    geom_text(data = my_data_detail,
              aes(x = 1, 
                  y = cumsum(Amount_scaled) - Amount_scaled/2,
                  label = label,
                  color = Sub.Category),
              parse = T,
              size = 4,
              show.legend = F)+
    scale_color_manual(values = myColors_text)+
    scale_fill_manual(name = "Source of AFOLU \nEmissions and \nRemovals",
                      values = myColors_AFOLU,
                      labels = str_wrap(names(myColors_AFOLU[(my_data_detail[,"Sub.Category"])[order(my_data_detail[,"Sub.Category"])]]),27))+
    ylim(0,max(sum(my_data_detail$Amount_scaled)))+
    coord_equal() +
    theme(plot.margin = unit(c(0, -0.5, 0, 0), "cm"),
          plot.title = element_text(size = 7.5/0.52, hjust = 0.5),
          plot.background = element_rect(fill = "White"))+ 
    theme_void()+
    xlab("Emissionss")+ 
    labs(title = TeX(paste0(round(sum(my_data_detail[,"Mt.CO2.equivalent"]), 0), "MtCO$_{",2,"}e")))+
    ylab(NULL)
  
  #If there are emissions & removals from AFOLU for your country
  if(exists("my_data_neg")){
    #plot the bar chart for emisions from AFOLU
    p_bar <- p + geom_tile(data = my_data_detail,
                           aes(x = 1,
                               y = cumsum(Amount_scaled) - Amount_scaled/2,
                               height = Amount_scaled, fill = Sub.Category),
                           show.legend = F) +
      geom_text(data = my_data_detail,
                aes(x = 1,
                    y = cumsum(Amount_scaled) - Amount_scaled/2,
                    label = label,
                    color = Sub.Category),
                parse = T,
                size = 4,
                show.legend = F)+
      scale_color_manual(values = myColors_text)+
      scale_fill_manual(values = myColors_AFOLU)+
      ylim(0,max(sum(my_data_detail_neg$Amount_scaled),
                 2))+
      coord_equal()+
      theme(plot.margin = unit(c(0, 0, 0, 0), "cm"),
            plot.background = element_rect(fill = "White"),
            axis.ticks = element_blank(),
            axis.line = element_blank(),
            axis.text = element_blank(),
            plot.title = element_text(size = 7.5/0.52, hjust = 0.5),
            axis.title.x = element_text(size = 7.5/0.52),
            panel.background = element_blank())+
      xlab("Emissions") +
      ylab(NULL) +
      labs(title = TeX(paste0(round(sum(my_data_detail[,"Mt.CO2.equivalent"]), 0), "MtCO$_{",2,"}e")))
    
    #add a label variable for sub categories that contributes enough to be readable
    my_data_detail_neg <- my_data_detail_neg %>%
      mutate(label = ifelse(Amount_scaled>0.20, TeX(paste0(round(Mt.CO2.equivalent,0), "MtCO$_{",2,"}e"), output = "character"), NA)) %>%
      data.frame()

    #nee to define the y axis range
    ylim_max <- ifelse(sum(my_data_detail_neg$Amount_scaled)>2,
                       sum(my_data_detail_neg$Amount_scaled),
                       2)
    #plot the bar chart for removals from AFOLU
    p_bar_neg <- p + geom_tile(data = my_data_detail_neg,
                               aes(x = 1,
                                   y = cumsum(Amount_scaled) - Amount_scaled/2,
                                   height = Amount_scaled, fill = Sub.Category),
                               show.legend = F) +
      geom_text(data = my_data_detail_neg,
                aes(x = 1,
                    y = cumsum(Amount_scaled) - Amount_scaled/2,
                    label = label,
                    color = Sub.Category),
                parse = T,
                size = 4,
                show.legend = F) +
      scale_color_manual(values = myColors_text)+
      scale_fill_manual(values = myColors_AFOLU)+
      ylim(0,max(sum(my_data_detail_neg$Amount_scaled),
                 2))+
      coord_equal()+
      theme(plot.margin = unit(c(0, 0, 0, 0), "cm"),
            plot.background = element_rect(fill = "White"),
            axis.ticks = element_blank(),
            axis.line = element_blank(),
            axis.text = element_blank(),
            plot.title = element_text(size = 7.5/0.52, hjust = 0.5),
            axis.title.x = element_text(size = 7.5/0.52),
            panel.background = element_blank())+
      xlab("Removals")+
      labs(title = TeX(paste0("  ",round(sum(my_data_detail_neg[,"Mt.CO2.equivalent"]), 0), "MtCO$_{",2,"}e")))+
      ylab(NULL)

    #If your country has more removal than emissions
    if(sum(my_data_detail_neg$Amount_scaled)>2){
      #plot the bar chart for removals from AFOLU
      p_bar_neg <- p + geom_tile(data = my_data_detail_neg,
                                 aes(x = 1,
                                     y = cumsum(Amount_scaled) - Amount_scaled/2,
                                     height = Amount_scaled, fill = Sub.Category),
                                 show.legend = F) +
        geom_text(data = my_data_detail_neg,
                  aes(x = 1,
                      y = cumsum(Amount_scaled) - Amount_scaled/2,
                      label = label,
                      color = Sub.Category),
                  parse = T,
                  size = 4,
                  show.legend = F) +
        scale_color_manual(values = myColors_text)+
        scale_fill_manual(values = myColors_AFOLU)+
        ylim(0,sum(my_data_detail_neg$Amount_scaled))+
        theme(plot.margin = unit(c(0, 0, 0, 0), "cm"),
              plot.background = element_rect(fill = "White"),
              axis.ticks = element_blank(),
              axis.line = element_blank(),
              axis.text = element_blank(),
              plot.title = element_text(size = 7.5/0.52, hjust = 0.5),
              axis.title.x = element_text(size = 7.5/0.52),
              panel.background = element_blank())+
        xlab("Removals")+
        labs(title = TeX(paste0("  ",round(sum(my_data_detail_neg[,"Mt.CO2.equivalent"]), 0), "MtCO$_{",2,"}e")))+
        ylab(NULL)

      #Placeholder needed to center the emissions bar chart so that it looks nicer
      placeholder <- (sum(my_data_detail_neg$Amount_scaled)- sum(my_data_detail$Amount_scaled))/sum(my_data_detail$Amount_scaled) -0.2
      
      temp_levels <- levels(as.factor(my_data_detail$Sub.Category))
      myColors_AFOLU <- c(myColors_AFOLU, "Z" = "white")
      
      #temp dataframe to add later to the dataframe ploted
      vect_temp <- my_data_detail[1,] %>% 
        mutate(Category = "AFOLU",
               Sub.Category = "Z",
               Amount_scaled = placeholder)
      
      my_data_detail <- my_data_detail %>% 
        rbind(vect_temp) %>% 
        mutate(Sub.Category = factor(Sub.Category, levels = c("Z", temp_levels))) %>% 
      #reorder to have the SubCategory Z first  
      my_data_detail <- my_data_detail[c(which(my_data_detail$Sub.Category == "Z"), which(my_data_detail$Sub.Category != "Z")),]
      #add a label variable for sub categories that contributes enough to be readable
      my_data_detail <- my_data_detail %>%
        mutate(label = ifelse((Amount_scaled/sum(my_data_detail_neg$Amount_scaled) > 0.15), TeX(paste0(round(Mt.CO2.equivalent,0), "MtCO$_{",2,"}e"), output = "character"), NA)) %>%
        data.frame()
      
      #plot the bar chart for emissions from AFOLU
      p_bar <- p + geom_tile(data = my_data_detail,
                             aes(x = 1,
                                 y = cumsum(Amount_scaled) - Amount_scaled/2,
                                 height = Amount_scaled,
                                 fill = Sub.Category),
                             show.legend = F,
                             color = "white") +
        geom_text(data = my_data_detail,
                  aes(x = 1,
                      y = cumsum(Amount_scaled) - Amount_scaled/2,
                      label = label,
                      color = Sub.Category),
                  parse = T,
                  size = 4,
                  show.legend = F) +
        scale_color_manual(values = myColors_text)+
        scale_fill_manual(values = myColors_AFOLU)+
        ylim(0,sum(my_data_detail_neg$Amount_scaled))+
        theme(plot.margin = unit(c(0, 0, 0, 0), "cm"),
              plot.background = element_rect(fill = "White"),
              axis.ticks = element_blank(),
              axis.line = element_blank(),
              axis.text = element_blank(),
              plot.title = element_text(size = 7.5/0.52, hjust = 0.5),
              axis.title.x = element_text(size = 7.5/0.52),
              panel.background = element_blank())+
        xlab("Emissions")+
        labs(title = TeX(paste0(round(sum(my_data_detail[,"Mt.CO2.equivalent"]), 0), "MtCO$_{",2,"}e")))+
        ylab(NULL)

    }

    #merge the two bars plot together
    p_bars <- plot_grid(p_bar ,
                        p_bar_neg,
                        nrow = 1,
                        align = "hv",
                        axis = "bl")

  }
  
  #legend if only emissions from AFOLU
  legend <- legend_emissions
  
  if(exists("my_data_neg")){
    #legend if emissions and reomvals from AFOLU
    legend <- plot_grid(legend_emissions,
                        legend_removals,
                        align = "hv",
                        nrow = 2,
                        rel_heights = if(country != "Colombia") c(1.6, 1.4) else c(2, 1))
  }
  
  
  #Merge donut and bar plots together if only emissions from AFOLU
  p_figure <- ggarrange(p_donut + 
                          theme(plot.margin = margin(r = -15, l = -50),
                                plot.background = element_rect(fill = "White")),  
                        p_bar + 
                          theme(plot.margin = margin(l = 0, r = -40),
                                plot.background = element_rect(fill = "White")), nrow = 1, widths = c( 3, 1.1))
  
  #add the legend to the plot
  p_final <- plot_grid(grid.arrange(
    grobs = list(p_figure, legend), 
    widths = c(2,1.5,1.85),
    heights = c(1,4.2,1),
    layout_matrix = rbind(c(NA, NA, 2),
                          c(1, 1, 2),
                          c(NA, NA, 2))))
  width_plot = 7.35
  
  
  if(exists("my_data_neg")){
    #Merge donut and bar plots together if emissions and removals from AFOLU
    p_figure <- ggarrange(p_donut +
                            theme(plot.margin = margin(r = -15, l = -50),
                                  plot.background = element_rect(fill = "White")),
                          p_bars +
                            theme(plot.margin = margin(l = 0, r = -20),
                                  plot.background = element_rect(fill = "White")),
                          nrow = 1,
                          widths = c( 2.2, 1.8))


    #add the legend to the plot
    p_final <- plot_grid(grid.arrange(
      grobs = list(p_figure, legend),
      widths = c(2.40, 0.4, 1.2, 1.8),
      heights = c(1,4.2,1),
      layout_matrix = rbind(c(NA, NA, NA, 2),
                            c(1, 1, 1, 2),
                            c(NA, NA, NA, 2))))

    width_plot = 8.80


  }
  
  rm(my_data_neg)
  
  outpath <- paste0(outpath, "Figure 3/")
  if(!dir.exists(outpath)){
    dir.create(outpath)
  }
  
  pdf(paste0(outpath, "Figure_3_", country, "_", gsub("-", "",Sys.Date()),".pdf"), bg = "white", height = 4, width = width_plot)
  plot(p_final)
  dev.off()
  
  png(paste0(outpath, "Figure_3_", country, "_", gsub("-", "",Sys.Date()),".png"), bg = "white", height = 4, width = width_plot, unit = "in", res = 600)
  plot(p_final)
  dev.off()
  
}

