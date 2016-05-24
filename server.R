# * Author:    Bangyou Zheng (Bangyou.Zheng@csiro.au)
# * Created:   09:24 PM Saturday, 26 March 2016
# * Copyright: AS IS


options(digits = 10)
library(shiny)
library(dplyr)
library(rgdal)
library(leaflet)
library(leafletplugins)
source('global.R')
shinyServer(function(input, output, session) {
  
    # Observe for change camera
    observe({
        req(input$i_camera_list)
        sel_camera <- cameras %>% 
            filter(name == input$i_camera_list)
        req(nrow(sel_camera) > 0)
        updateNumericInput(
            session
            , 'i_img_sensor_x'
            , value = sel_camera$img_sensor_x)
        updateNumericInput(
            session
            , 'i_img_sensor_y'
            , value = sel_camera$img_sensor_y)
        updateNumericInput(
            session
            , 'i_focus_length'
            , value = sel_camera$focus_length)
        img_sensor_x <- input$i_img_sensor_x
        img_sensor_y <- input$i_img_sensor_y
        if(input$i_camera_angle == 'Portrait') {
            img_sensor_x <- input$i_img_sensor_y
            img_sensor_y <- input$i_img_sensor_x
        }
        res <- calc.settings(input$i_flight_height, 
                      input$i_shutter_interval,
                      input$i_overlap_x / 100,
                      input$i_overlap_y / 100,
                      input$i_img_sensor_x,
                      input$i_img_sensor_y,
                      input$i_focus_length)
        #print(res)
        updateNumericInput(
            session
            , 'i_grid_offset'
            , value = res$turn.dis)
        updateNumericInput(
          session
          , 'i_flight_speed'
          , value = res$speed.drone.km.h)
        #output$o_flight_speed <- renderText(res$speed.drone.km.h)
        if(res$speed.drone > input$i_maximum_flight_speed)
            output$o_flight_speed_caution <- renderText("Caution: over speed!")
    })
    
    output$o_map <- renderLeaflet({

        map <- leaflet() %>%
            addTiles(group = 'OSM') %>% 
            addProviderTiles(
                'Esri.WorldImagery', group = 'Satellite'
                , options = tileOptions(maxZoom = 28, maxNativeZoom = 17)) %>% 
            addDrawToolbar(
                layerID = 'draw', group = 'Field'
                , polyline = FALSE, polygon = TRUE
                , rectangle = FALSE, circle = FALSE
                , marker = FALSE, edit = TRUE, remove = TRUE
                , position = 'topleft') %>% 
            addScaleBar('bottomleft', options = scaleBarOptions(imperial = FALSE)) %>% 
            addControlGPS() %>% 
            
            addSearchOSM(url ='https://nominatim.openstreetmap.org/search?format=json&q={s}',
                         position = 'topright') %>% 
            addLayersControl(
                baseGroups = c('OSM', 'Satellite')
                , overlayGroups = c('Field', 'Flight')
                , options = layersControlOptions(collapsed = FALSE)
            )
        geoloc <- input$ip_address
        if (!is.null(geoloc)) {
            map <- map %>%
                setView(lng = as.numeric(geoloc$longitude),
                        lat = as.numeric(geoloc$latitude),
                        zoom = 16)
        }        
        map 
    })

    # Reactive for way points
    r_way_points <- reactive({
        req(input$o_map_draw_features)
        req(input$i_grid_offset)
        offset <- input$i_grid_offset
        ply <- input$o_map_draw_features
        req(length(ply$features) > 0)
        # save(list = ls(), file = 'tmp.RData')
        
        wp <- way_points(ply, offset = offset)

        wp <- spTransform(wp,  CRS('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))
        
        wp
    })
    
    # Reactive for output data
    output_data <- reactive({
      req(input$i_flight_height)
      altitude <- input$i_flight_height
      wp <- r_way_points()
      wp <- as.data.frame(wp)
      names(wp) <- c('longitude', 'latitude')
      
      # add the starting point
      #wp <- rbind(wp, wp[1,])
      
      # calculate slope (added by hw)
      res <- heading.distance.direction(wp)
      distance <- res$distance
      direction <- res$direction
      if(input$i_heading_direction == 1)
        direction <- direction[1]
      if(input$i_camera_angle == 'Portrait')
        direction <- direction - 90
      direction[direction < 0] <- direction[direction < 0] + 360
      
      speed <- rep(input$i_flight_speed, length(distance))
      #speed[length(speed)] <- 0
      

      # update information
      total.distance <- sum(distance)
      flight.duration <- total.distance / (input$i_flight_speed * 1000 / 60)
      output$o_flight_speed <- renderText(input$i_flight_speed)
      output$o_flight_distance <- renderText(total.distance)
      output$o_flight_duration <- renderText(flight.duration)
      if (flight.duration > input$i_battery_life * 0.7)
          output$o_flight_duration_caution <- renderText("Caution: over duration!")
      wp %>% 
          select(latitude, longitude) %>% 
          mutate(altitude = altitude,
                 heading = direction,
                 distance = distance,
                 speed = speed)
      
    })
    
    # draw table
    output$grouping <- renderTable({
      output_data()
    })
    
    
    # Download output file
    output$o_download_wp <- downloadHandler(
        filename = function() {
            switch(input$i_filetype
                   , Litchi = paste0(input$i_filename,'.csv')
                   , Ardupilot = paste0(input$i_filename,'.waypoints'))
        },
        content = function(file) {
            wp <- output_data()
            if (input$i_filetype == 'Litchi') {
                wp1 <- wp %>% 
                    select(latitude,
                           longitude,
                           `altitude(m)` = altitude,
                           `heading(deg)` = heading) %>% 
                    mutate(
                           `curvesize(m)` = 0.2,
                           `rotationdir` = 0,
                           `gimbalmode`	= 0,
                           `gimbalpitchangle` = 0,
                           `actiontype1` = -1,
                           `actionparam1` = 0,
                           `actiontype2` = -1,
                           `actionparam2` = 0,
                           `actiontype3` = -1,
                           `actionparam3` = 0,
                           `actiontype4` = -1,
                           `actionparam4` = 0,
                           `actiontype5` = -1,
                           `actionparam5` = 0,
                           `actiontype6` = -1,
                           `actionparam6` = 0,
                           `actiontype7` = -1,
                           `actionparam7` = 0,
                           `actiontype8` = -1,
                           `actionparam8` = 0,
                           `actiontype9` = -1,
                           `actionparam9` = 0,
                           `actiontype10` = -1,
                           `actionparam10` = 0,
                           `actiontype11` = -1,
                           `actionparam11` = 0,
                           `actiontype12` = -1,
                           `actionparam12` = 0,
                           `actiontype13` = -1,
                           `actionparam13` = 0,
                           `actiontype14` = -1,
                           `actionparam14` = 0, 
                           `actiontype15` = -1,
                           `actionparam15` = 0)
                write.csv(wp1, file = file, row.names = FALSE)
            } else if (input$i_filetype == 'Ardupilot') {
                wp1 <- c('QGC WPL 110',
                            '1	0	3	22	20.000000	0.000000	0.000000	0.000000	0.000000	0.000000	30.000000	1',
                            '2	0	3	178	0.000000	5.000000	0.000000	0.000000	0.000000	0.000000	0.000000	1'
                )
                wp2 <- data.frame(V0 = seq(3, length.out = nrow(wp))
                                  , V1 =  '0	3	16	0.000000	0.000000	0.000000	0.000000'
                                  , V2 = wp$latitude
                                  , V3 = wp$longitude
                                  , V4 = wp$altitude
                                  , V5 = 1) %>% 
                    apply(1, FUN = paste, collapse = '\t')
                wp1 <- c(wp1, wp2
                            , c('55	0	3	206	0.000000	0.000000	0.000000	0.000000	0.000000	0.000000	0.000000	1'
                                , '56	0	3	20	0.000000	0.000000	0.000000	0.000000	0.000000	0.000000	0.000000	1'
                                
                            ))
                writeLines(wp1, file)
            }
        }
    )
    
    # Draw a polygon 
    observe({
        wp <- r_way_points()
        fly_lines <- SpatialLines(list(Lines(list(Line(wp)), ID = 1)),
                                  proj4string = wp@proj4string)
        
        proxy <- leafletProxy('o_map')
        proxy %>%
            clearPopups() %>%
            clearGroup('Flight') %>% 
            addPolylines(data = fly_lines, group = 'Flight')
    })
    
    observe({
        req(input$o_map_draw_editing)
        leafletProxy('o_map') %>%
            clearPopups() %>%
            clearGroup('Flight')
    })
    
    observe({
        req(input$o_map_draw_deleting)
        leafletProxy('o_map') %>%
            clearPopups() %>%
            clearGroup('Flight')
    })
})
