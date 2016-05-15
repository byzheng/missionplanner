# * Author:    Bangyou Zheng (Bangyou.Zheng@csiro.au)
# * Created:   09:24 PM Saturday, 26 March 2016
# * Copyright: AS IS



library(shiny)
library(dplyr)
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
        updateSliderInput(
          session
          , 'i_flight_speed'
          , value = floor(res$speed.drone.km.h))
        updateNumericInput(
          session
          , 'o_flight_speed'
          , value = res$speed.drone.km.h)
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
        
        wp <- wp <- way_points(ply, offset = offset)

        wp <- spTransform(wp,  CRS('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))
        
        wp
    })
    
    
    # Download excel file
    output$o_download_wp <- downloadHandler(
        filename = function() {
            paste0(input$i_filename,'.csv')
        },
        content = function(file) {
            req(input$i_flight_height)
            altitude <- input$i_flight_height
            wp <- r_way_points()
            # save(wp, file = 'tmp.RData')
            wp <- as.data.frame(wp)
            names(wp) <- c('longitude', 'latitude')
            
            # add the starting point
            wp <- rbind(wp, wp[1,])
            
            # calculate slope (added by hw)
            res <- heading.distance.direction(wp)
            distance <- res$distance
            direction <- res$direction
            if(input$i_heading_direction == 1)
              direction <- direction[1]
            if(input$i_camera_angle == 'Portrait')
              direction <- direction - 90
            direction[direction < 0] <- direction[direction < 0] + 360
            
            speed <- rep(input$o_flight_speed, length(distance))
            speed[length(speed)] <- 0
            
            wp <- wp %>% 
                select(latitude, longitude) %>% 
                mutate(`altitude(m)` = altitude,
                       `heading(deg)` = direction,
                       `curvesize(m)` = 0.2,
                       `rotationdir` = 0,
                       `distance` = distance,
                       `speed` = speed)
            write.csv(wp, file = file, row.names = FALSE)
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
