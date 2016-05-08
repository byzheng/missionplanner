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
            
            wp <- wp %>% 
                select(latitude, longitude) %>% 
                mutate(`altitude(m)` = altitude,
                       `heading(deg)` = 0,
                       `curvesize(m)` = 0.2,
                       `rotationdir` = 0)
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
