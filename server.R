# * Author:    Bangyou Zheng (Bangyou.Zheng@csiro.au)
# * Created:   09:24 PM Saturday, 26 March 2016
# * Copyright: AS IS





# Show more digits in the outputs for high accuracy
options(digits = 15)
colour_value_map <- function(value, constrains, reverse = FALSE) {
    col <- c('green', 'blue', 'yellow', 'orange', 'red')
    if (reverse) { col = rev(col)}
    pos <- length(col) - which.min(rev(value <= constrains)) + 1
    col[pos]
}

library(RCurl)
library(shiny)
library(dplyr)
library(rgdal)
library(leaflet)
library(leaflet.extras)
source('global.R')
shinyServer(function(input, output, session) {
    # Reactive for camera
    r_camera <- reactive({
        x <- getURL("https://raw.githubusercontent.com/byzheng/missionplanner/master/camera.csv")
        y <- read.csv(text = x)
        y
    })
    observe({
        cameras <- r_camera()
        updateSelectInput(
            session, 'i_camera_list',
            choices = cameras$name, 
            selected = cameras$name[1])
    })
    # Reactive for speed
    r_speed <- reactive({
        speed <- input$i_flight_speed
        if (input$i_speed_unit == 'm/s') {
            speed <- speed * 3.6
        }
        speed
    })
    # Observe for unit
    observe({
        req(input$i_speed_unit)
        new_speed <- isolate(input$i_flight_speed)
        if (input$i_speed_unit == 'km/h') {
            new_speed <- new_speed * 3.6
        } else {
            new_speed <- new_speed / 3.6
        }

        updateNumericInput(session, 'i_flight_speed', value = new_speed)
    })
    # Observe for change camera
    observe({
        req(input$i_camera_list)
        cameras <- r_camera()
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
        updateNumericInput(
            session
            , 'i_img_res_x'
            , value = sel_camera$resolution_x)
        updateNumericInput(
            session
            , 'i_img_res_y'
            , value = sel_camera$resolution_y)

        img_sensor_x <- input$i_img_sensor_x
        img_sensor_y <- input$i_img_sensor_y
        if(input$i_camera_direction == 'Landscape') {
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
        isolate({
            speed <- ifelse(input$i_speed_unit == 'm/s',
               res$speed.drone.km.h / 3.6, res$speed.drone.km.h)
        })
        updateNumericInput(
          session
          , 'i_flight_speed'
          , value = speed)
    })


    output$o_map <- renderLeaflet({

        map <- leaflet() %>%
            addTiles(
                group = 'OSM'
                , options = tileOptions(maxZoom = 28, maxNativeZoom = 19)) %>%
            addProviderTiles(
                'Esri.WorldImagery', group = 'Satellite'
                , options = tileOptions(maxZoom = 28, maxNativeZoom = 17)) %>%
            addDrawToolbar(
                targetGroup = 'Field'
                , polylineOptions = FALSE, polygonOptions = drawPolygonOptions()
                , circleOptions = FALSE, rectangleOptions = FALSE
                , markerOptions = FALSE, editOptions = editToolbarOptions()
                , position = 'topleft') %>%
            addScaleBar('bottomleft', options = scaleBarOptions(imperial = FALSE)) %>%
            addControlGPS() %>%
            addMeasure(position = 'bottomleft'
                       , primaryAreaUnit = 'sqmeters'
                       , primaryLengthUnit = 'meters') %>%
            addSearchOSM(options = searchOSMOptions(position = 'topright')) %>%
            addLayersControl(
                baseGroups = c('OSM', 'Satellite')
                , overlayGroups = c('Field', 'Flight', 'Points')
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


    # Upload points
    observe({
        in_file <- input$i_import_file

        if (is.null(in_file))
            return(NULL)
        points <- read.table(in_file$datapath, header = TRUE)


        req(nrow(points) > 0)
        req(points$latitude)
        req(points$longitude)

        updateTabItems(session, 'menu_tabs', 'm_field')
        proxy <- leafletProxy('o_map')
        proxy %>%
            addMarkers(lat = points$latitude, lng = points$longitude, group = 'Points') %>%
            setView(lat = mean(points$latitude), lng = mean(points$longitude), zoom = 15)
    })

    # Reactive for way points
    r_way_points <- reactive({
        req(input$o_map_draw_all_features)
        req(input$i_grid_offset)
        offset <- input$i_grid_offset
        ply <- input$o_map_draw_all_features
        req(length(ply$features) > 0)
        # save(list = ls(), file = 'tmp.RData')

        wp <- way_points(ply, offset = offset)

        wp <- spTransform(wp,  CRS('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'))

        wp
    })

    r_output_data_tbl <- reactive({
        req(input$i_flight_height)
        altitude <- input$i_flight_height
        wp <- r_way_points()
        wp <- as.data.frame(wp)
        names(wp) <- c('longitude', 'latitude')

        # add the starting point
        #wp <- rbind(wp, wp[1,])

        # calculate slope (added by hw)
        res <- heading.distance.direction(wp)
    })
    # Reactive for output data
    output_data <- reactive({
        altitude <- input$i_flight_height

        res <- r_output_data_tbl()
        wp <- r_way_points()
        wp <- as.data.frame(wp)
        names(wp) <- c('longitude', 'latitude')

        distance <- res$distance
        direction <- res$direction
        if (input$i_heading_direction == 1)
        direction <- direction[1]
        if (input$i_camera_direction == 'Portrait')
        direction <- direction - 90
        direction[direction < 0] <- direction[direction < 0] + 360

        speed <- rep(r_speed(), length(distance))
        #speed[length(speed)] <- 0


        # update information
        total.distance <- sum(distance)
        flight.duration <- total.distance / (input$i_flight_speed * 1000 / 60)

        # if (flight.duration > input$i_battery_life * 0.7)
        #   output$o_flight_duration_caution <- renderText("Caution: over duration!")
        wp %>%
          select(latitude, longitude) %>%
          mutate(altitude = altitude,
                 heading = direction,
                 distance = distance,
                 speed = speed)

    })


    # Output information box
    output$o_infor_flight_speed <- renderInfoBox({
        i_flight_speed <- r_speed() / 3.6
        col <- colour_value_map(i_flight_speed, quantile(c(0, input$i_maximum_flight_speed)))
        infoBox(
            title = 'Speed (m/s)'
            , value = i_flight_speed
            , icon = shiny::icon('rocket')
            , subtitle = paste('Maximum ', input$i_maximum_flight_speed, ' m/s')
            , width = 6
            , fill = TRUE
            , color = col)

    })
    output$o_infor_flight_distance <- renderInfoBox({
        distance <- round(sum(r_output_data_tbl()$distance), 0)
        max_distance <- input$i_maximum_flight_speed * input$i_battery_life * 60
        col <- colour_value_map(distance, quantile(c(0, max_distance)))

        infoBox(
            title = 'Distance (m)'
            , value = distance
            , icon = shiny::icon('road', lib = 'glyphicon')
            , width = 6
            , fill = TRUE
            , subtitle = paste('Maximum ', max_distance, ' m')
            , color = col)

    })


    output$o_infor_flight_duration <- renderInfoBox({
        distance <- r_output_data_tbl()$distance
        flight_duration <- round(sum(distance) / (r_speed() / 3.6 * 60), 1)
        col <- colour_value_map(flight_duration, quantile(c(0, input$i_battery_life)))

        infoBox(
            title = 'Duration (min)'
            , value = flight_duration
            , icon = shiny::icon('clock-o')
            , width = 6
            , fill = TRUE
            , subtitle = paste('Maximum ', input$i_battery_life, ' min')
            , color = col)
    })

    r_range_img <- reactive({
        altitude <- input$i_flight_height
        imgsensor_x <- input$i_img_sensor_x
        imgsensor_y <- input$i_img_sensor_y
        focus_length <- input$i_focus_length

        range_x <- (altitude * imgsensor_x) / focus_length
        range_y <- (altitude * imgsensor_y) / focus_length
        if (input$i_camera_direction == 'Landscape') {
            a <- range_x
            range_x <- range_y
            range_y <- a
        }
        list(x = range_x, y = range_y)
    })
    r_overlap_img <- reactive({
        rng <- r_range_img()
        shutter_interval <- input$i_shutter_interval
        flight_speed <- r_speed() / 3.6

        grid_offset <- input$i_grid_offset
        overlap_x <- 100 - ((shutter_interval * flight_speed) / rng$x) * 100
        overlap_y <- 100 - grid_offset / rng$y * 100
        list(x = overlap_x, y = overlap_y)
    })

    output$o_infor_range_x <- renderInfoBox({
        range <- r_range_img()

        infoBox(
            title = 'Range in X (m)'
            , value = round(range$x)
            , icon = shiny::icon('file-image-o')
            , width = 6
            , fill = TRUE
            , color = 'blue')
    })

    output$o_infor_range_y <- renderInfoBox({
        range <- r_range_img()

        infoBox(
            title = 'Range in Y (m)'
            , value = round(range$y)
            , icon = shiny::icon('file-image-o')
            , width = 6
            , fill = TRUE
            , color = 'blue')
    })


    output$o_infor_overlap_x <- renderInfoBox({
        overlap <- r_overlap_img()
        col <- colour_value_map(overlap$x, quantile(c(50, 90)), reverse = TRUE)

        infoBox(
            title = 'Overlap in X (%)'
            , value = round(overlap$x)
            , icon = shiny::icon('file-image-o')
            , width = 6
            , fill = TRUE
            , color = col)
    })


    output$o_infor_overlap_y <- renderInfoBox({
        overlap <- r_overlap_img()
        col <- colour_value_map(overlap$y, quantile(c(50, 90)), reverse = TRUE)

        infoBox(
            title = 'Overlap in Y (%)'
            , value = round(overlap$y)
            , icon = shiny::icon('file-image-o')
            , width = 6
            , fill = TRUE
            , color = col)
    })


    output$o_infor_gsd <- renderInfoBox({

        req(input$i_img_res_x)
        req(input$i_img_res_y)
        i_img_res_x <- input$i_img_res_x
        i_img_res_y <- input$i_img_res_y

        if (input$i_camera_direction == 'Landscape') {
            a <- i_img_res_x
            i_img_res_x <- i_img_res_y
            i_img_res_y <- a
        }
        overlap <- r_range_img()
        gsd <- (overlap$x / i_img_res_x + overlap$y / i_img_res_y) / 2 * 1000

        infoBox(
            title = 'Ground sampling distance (mm)'
            , value = round(gsd, 2)
            , icon = shiny::icon('arrows-h')
            , width = 6
            , fill = TRUE
            , color = 'blue')
    })


    output$o_flight_height <- renderInfoBox({

        infoBox(
            title = 'Flight height (m)'
            , value = input$i_flight_height
            , icon = shiny::icon('arrows-v')
            , width = 6
            , fill = TRUE
            , color = 'blue')
    })


    # draw table
    output$o_summary_tbl <- renderTable({
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
                           `actionparam15` = 0,
                           `distance(m)` = wp$distance,
                           `speed` = wp$speed)
                write.csv(wp1, file = file, row.names = FALSE)
            } else if (input$i_filetype == 'Ardupilot') {
                wp1 <- c('QGC WPL 110',
                            '1	0	3	22	20.000000	0.000000	0.000000	0.000000	0.000000	0.000000	30.000000	1'
                                )
                wp1 <- c(wp1, sprintf(
                    '2	0	3	178	0.000000	%f	0.000000	0.000000	0.000000	0.000000	0.000000	1'
                    , wp$speed[1]
                ))
                wp2 <- data.frame(V0 = seq(3, length.out = nrow(wp))
                                  , V1 =  '0	3	16	0.000000	0.000000	0.000000	0.000000'
                                  , V2 = wp$latitude
                                  , V3 = wp$longitude
                                  , V4 = wp$altitude
                                  , V5 = 1) %>%
                    apply(1, FUN = paste, collapse = '\t')
                wp2[1] <- gsub('16	0.000000', '16	3.000000',  wp2[1])
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
        req(input$o_map_draw_editstart)
        leafletProxy('o_map') %>%
            clearPopups() %>%
            clearGroup('Flight')
    })

    observe({
        req(input$o_map_draw_deletestart)
        leafletProxy('o_map') %>%
            clearPopups() %>%
            clearGroup('Flight')
    })
})
