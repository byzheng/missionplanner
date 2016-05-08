# * Author:    Bangyou Zheng (Bangyou.Zheng@csiro.au)
# * Created:   08:52 PM Wednesday, 20 April 2016
# * Copyright: AS IS

cameras <- read.csv('camera.csv', as.is = TRUE)

utm_zone <- function(lng, lat) {
    ZoneNumber <- floor((lng + 180)/6) + 1;
    
    if (lat >= 56.0 & lat < 64.0 & lng >= 3.0 & lng < 12.0 ) {
        ZoneNumber <- 32
    }
    if (lat >= 72.0 & lat < 84.0) {
        if (lng >= 0.0 && lng < 9.0) {
            ZoneNumber <- 31
        } else if (lng >= 9.0  & lng < 21.0) {
            ZoneNumber <- 33
        } else if (lng >= 21.0 & lng < 33.0) {
            ZoneNumber <- 35
        } else if (lng >= 33.0 & lng < 42.0 ) {
            ZoneNumber <- 37
        }
    }
    ZoneNumber
} 


way_points <- function(
    geojson, offset, 
    proj4string = CRS('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')) {
    
    library(sp)
    
    # Reorganize the coordinates
    coordinate <- geojson$features[[1]]$geometry$coordinates[[1]]
    
    coor_matrix <- matrix(NA, ncol = 2, nrow = length(coordinate))
    for (i in seq(along = coordinate)) {
        coor_matrix[i,] <- c(coordinate[[i]][[1]], coordinate[[i]][[2]])
    }
    
    coor_matrix <- unique(coor_matrix)
    
    polygon <- SpatialPolygons(
        list(Polygons(list(Polygon(coor_matrix)), ID = '1')),
        proj4string = proj4string)
    
    # Guess the utm zone
    utm_zone <- utm_zone(mean(coor_matrix[,1]), mean(coor_matrix[,2]))
    
    new_crs <- CRS(
        paste0('+proj=utm +zone=', utm_zone, 
               ' +datum=WGS84 +units=m +no_defs +ellps=WGS84 +towgs84=0,0,0'))
    polygon <- spTransform(polygon, new_crs)
    
    # Get the coordinates of polygon    
    ply_coor <- spTransform(SpatialPoints(
        coor_matrix, 
        proj4string = proj4string),
        polygon@proj4string)
    ply_coor <-  ply_coor@coords
    
    
    # Use the first two points to calculate the slope
    slope <- atan((ply_coor[1,2] - ply_coor[2,2]) / (ply_coor[1,1] - ply_coor[2,1]))
    
    # Transfer the line according to an angle and distance
    newpos <- function(input, bearing, distance) {
        x <- input[1] + distance * cos(bearing)
        y <- input[2] + distance * sin(bearing)
        matrix(c(x, y), ncol = 2)
    }
    
    # Get the sdistance of all points to the first two points in the polygon
    l <- SpatialLines(list(Lines(list(Line(ply_coor[1:2,])), ID = 1)))
    p <- SpatialPoints(ply_coor)
    dis <- rgeos::gDistance(p, l,  byid = TRUE) 
    
    # Get the offset intervals 
    intervals <- seq(from = 0, to = max(dis), by = offset)
    intervals <- c(intervals[-1], -intervals[-1])
    
    # Extend the first point to make sure intersection
    p1 <- newpos(ply_coor[1,], slope, 9000000)
    p2 <- newpos(ply_coor[1,], slope, -9000000)
    
    # Get the new coordinates for two points accoridng the intervals
    new_p1 <- newpos(p1, slope + pi / 2, intervals)
    new_p2 <- newpos(p2, slope + pi / 2, intervals)
    
    # Make the spatial lines
    ply_crs <- polygon@proj4string
    
    new_lines <- list()
    for (i in seq(along = intervals)) {
        new_lines[[i]] <- Lines(list(Line(rbind(new_p1[i,], new_p2[i,]))), ID = i)
    }
    new_lines <- SpatialLines(new_lines, proj4string = ply_crs)
    
    # Find the intersection
    inter <- rgeos::gIntersection(new_lines, polygon, byid = TRUE)
    
    # Get the way points 
    way_points <- matrix(NA, ncol = 2, nrow = (length(inter) + 1) * 2)
    way_points[1:2,] <- ply_coor[1:2,]
    
    line1 <- inter@lines[[1]]@Lines[[1]]@coords
    dis <- (line1[,1] - ply_coor[1,1]) * (line1[,1] - ply_coor[1,1]) +
        (line1[,2] - ply_coor[1,2]) * (line1[,2] - ply_coor[1,2])
    check <- 1
    if (which.min(dis) == 2) {
        check <- 0
    }
    
    for (i in seq(along = inter)) {
        pos <- seq(1, 2)
        if (i %% 2 == check) {
            pos <- rev(pos)
        }
        l_coor <- inter@lines[[i]]@Lines[[1]]@coords[pos,]
        way_points[seq(i * 2 + 1, (i + 1) * 2), ] <- l_coor
    }
    
    way_points_sp <- SpatialPoints(way_points, proj4string = ply_crs)
    way_points_sp
}

