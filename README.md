# MissionPlanner
A Shiny APP to design flight mission. 

## Introduction

This shiny app is designed to easily plan your flight mission with a few simple rules.

See live version here: https://croptsrv-cdc.it.csiro.au/shiny/users/zhe00a/missionplanner/

## Update camera list
The camera list is directly red from github (https://github.com/byzheng/missionplanner/blob/master/camera.csv). Feel free to change this file and submit a pull request. After merging into the master branch, the camera list will be updated in a few second. You need to refresh the whole page to update the camera list. 

## Deploy 
This Shiny app required the latest version of leaftlet and leatlet.extras packages.
```r
devtools::install_github('rstudio/leaflet')
devtools::install_github('bhaskarvk/leaflet.extras')
```

## License
MIT License
