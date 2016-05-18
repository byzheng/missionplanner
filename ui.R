# * Author:    Bangyou Zheng (Bangyou.Zheng@csiro.au)
# * Created:   09:24 PM Saturday, 26 March 2016
# * Copyright: AS IS

ui_configuration <- function() {
    tabsetPanel(
        tabPanel(
            title = 'UAV'
            , sliderInput(
                inputId = 'i_flight_height'
                , label = 'Flight height (m)' 
                , value = 20, min = 5, max = 200, step = 1)
            , sliderInput(
                inputId = 'i_maximum_flight_speed'
                , label = 'Maximum flight speed (m/s)'
                , value = 10, min = 1, max = 30, step = 1)
            , sliderInput(
                inputId = 'i_battery_life'
                , label = 'Battery life (min)'
                , value = 15, min = 5, max = 60, step = 1 
            )
            , radioButtons(
              inputId = 'i_heading_direction'
              , label = "Heading direction"
              , choices = list("Keep initial direction" = 1, 
                               "Toward next waypoint" = 2)
              , selected = 1
            )
            , numericInput(
                inputId = 'i_grid_offset'
                , label = 'Shift in grid (m)'
                , value = 10
                , min = 1
                , max = 100
                #, step = 1
            )
            , numericInput(
              inputId = 'i_flight_speed'
              , label = 'Flight speed (km/h)'
              , value = 10
              , min = 1
              , max = 30
              #, step = 1
            )
        )
        , tabPanel(
            title = 'Camera'
            , selectInput(
                inputId = 'i_camera_list'
                , label = 'Camara'
                , choices  = cameras$name
                , selected = cameras$name[1])
            , sliderInput(
                inputId = 'i_shutter_interval'
                , label = 'Shutter Interval (s)'
                , value = 2, min = 1, max = 60, step = 1)
            , numericInput(
                inputId = 'i_img_sensor_x'
                , label = 'Image Sensor X (mm)'
                , value = 17.3, min = 1, max = 100, step = 0.1)
            , numericInput(
                inputId = 'i_img_sensor_y'
                , label = 'Image Sensor Y (mm)'
                , value = 13.0, min = 1, max = 100, step = 0.1)
            , numericInput(
                inputId = 'i_focus_length'
                , label = 'Focus Length (mm)'
                , value = 15, min = 1, max = 100, step = 0.1)
            , selectInput(
                inputId = 'i_camera_direction'
                , label = 'Camera Orientation'
                , choices = c('Landscape', 'Portrait')
                , selected = 'Landscape'
            )
            , sliderInput(
                inputId = 'i_camera_angle'
                , label = 'Camera angle (degree)'
                , min = -90, max = 90, value = 0
            ) 
        )
        , tabPanel(
            title = 'Field'
            # ,  fileInput(
            #     inputId = 'i_import_file'
            #     , label = 'Import field'
            # )
            , radioButtons(
                inputId = 'i_flight_mode'
                , label = 'Flight mode'
                , choices = c('Grid' = 'fm_grid')
                , selected = 'fm_grid'
                , inline = TRUE)

            , sliderInput(
                inputId = 'i_overlap_x'
                , label = 'Overlap X (%)'
                , value = 80, min = 0, max = 100)
            , sliderInput(
                inputId = 'i_overlap_y'
                , label = 'Overlap Y (%)'
                , value = 80, min = 0, max = 100)
       )
    )
    
}


library(shiny)
library(shinydashboard)
library(leaflet)
source('global.R')
header <- dashboardHeader(
    title = 'Mission Planner for UAV'
    , titleWidth = 300)

sidebar <- dashboardSidebar(
    width = 300
    , sidebarMenu(id = 'menu_tabs'
        , menuItem('Configuration', tabName = 'm_configuration')
        , menuItem('Field', tabName = 'm_field')
        , menuItem('Table', tabName = 'm_table')
        , menuItem('Summary', tabName = 'm_summary'))
)

body <- dashboardBody(
    singleton(
        tags$head(
            tags$script(src = "geolocation.js", type = 'text/javascript')))
    , tags$body(onload = "getip()")
    , tags$head(
        tags$link(rel = "stylesheet", type = "text/css", href = "style.css"))
    , tags$script(
        '$(".sidebar-toggle").on("click", function() { $(this).trigger("shown"); });')
    , tabItems(
        tabItem(
            tabName = 'm_field'
            , tags$div(
                class = 'outer',
                leafletOutput('o_map', width = '100%', height = '100%'))
        )
        , tabItem(
            tabName = 'm_configuration'
            , ui_configuration()
        )
        , tabItem(
            tabName = 'm_table'
            , tableOutput("grouping")
        )
        , tabItem(
            tabName = 'm_summary'
            , h5('Flight distance (m)')
            , textOutput('o_flight_distance')
            , h5('Flight speed (km/h)')
            , textOutput('o_flight_speed')
            , textOutput('o_flight_speed_caution')
            , h5('Flight duration (min)')
            , textOutput('o_flight_duration')
            , textOutput('o_flight_duration_caution')
            , textInput('i_filename', 'Filename without extension', 'litchi')
            , downloadButton('o_download_wp', 'Download waypoints')
        )
        )
         
)

dashboardPage(
    header, sidebar, body
    , title = 'Mission Planner for UAV'
)