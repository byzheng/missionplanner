# * Author:    Bangyou Zheng (Bangyou.Zheng@csiro.au)
# * Created:   09:24 PM Saturday, 26 March 2016
# * Copyright: AS IS

ui_help <- function() {
    includeMarkdown("help.md")
}

ui_configuration <- function() {
    tabsetPanel(
        tabPanel(
            title = 'UAV'
            , numericInput(
                inputId = 'i_flight_height'
                , label = 'Flight height (m)' 
                , value = 20, min = 5, max = 200, step = 1)
            , numericInput(
                inputId = 'i_maximum_flight_speed'
                , label = 'Maximum flight speed (m/s)'
                , value = 10, min = 1, max = 30, step = 1)
            , numericInput(
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
            , numericInput(
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
            , numericInput(
                inputId = 'i_img_res_x'
                , label = 'Image Resolution X (pixel)'
                , value = 2000, min = 100, max = 8000, step = 100)
            , numericInput(
                inputId = 'i_img_res_y'
                , label = 'Image Sensor Y (pixel)'
                , value = 2000, min = 100, max = 8000, step = 100)
            
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
            ,  fileInput(
                inputId = 'i_import_file'
                , label = 'Import key points (any text file with two columns (latitude and longitude))'
            )
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
        , menuItem('Summary', tabName = 'm_summary')
        , menuItem('Help', tabName = 'm_help'))
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
            , tableOutput("o_summary_tbl")
        )
        , tabItem(
            tabName = 'm_summary'
            , fluidRow(
                infoBoxOutput('o_infor_flight_speed')
                , infoBoxOutput('o_infor_flight_distance')
                , infoBoxOutput('o_infor_flight_duration')
            )
            , fluidRow(
                infoBoxOutput('o_infor_overlap_x')
                , infoBoxOutput('o_infor_overlap_y')
                , infoBoxOutput('o_infor_gsd')
            )
            , selectInput('i_filetype', 'File type'
                          , selected = 'Litchi'
                          , choices = c('Litchi', 'Ardupilot'))
            , textInput('i_filename', 'Filename without extension', 'waypoint')
            , downloadButton('o_download_wp', 'Download waypoints')
        )
        , tabItem(
            tabName = 'm_help',
            ui_help()
        )
        )
         
)

dashboardPage(
    header, sidebar, body
    , title = 'Mission Planner for UAV'
)