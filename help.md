
# Contributors

- Bangyou Zheng <Bangyou.Zheng@csiro.au>
- Hiroyoshi IWATA <aiwata@mail.ecc.u-tokyo.ac.jp>
- Wei Guo <guowei@isas.a.u-tokyo.ac.jp>
- Scott Chapman <Scott.Chapman@csiro.au>
- Pengcheng Hu <hupc23@gmail.com>

# How to use

### Generate waypoints

1. Go to [Mission Planner for UAV](byzheng.shinyapps.io/missionplanner/).

2. **Configuration**
  - *UAV* tab: sets `Flight height`, `Maximum flight speed`, `Battery life` and `Heading direction` for UAV. NOTE that `Shift in grid` and `Flight speed` can be automatically calculated by the app based on `Shutter interval` in *Camera* tab, `Overlap X` and `Overlap Y` in *Field* tab, there is no need to set these pareameters manually.
  - *Camera* tab: sets `Camera type`, `Shutter interval`, `Camera Orientation` and `Camera angle`. NOTE that `Image Sensor X`, `Image Sensor Y` and `Focus Length` will be changed automatically acoording to `Camera type`.
  - *Field* tab: sets `Flight mode`, `Overlap X` and `Overlap Y`. `Overlap X` means forward overlap (image height) and `Overlap Y` means side overlap (image width).

3. **Field** 
 - Click `draw a polygon` button and select the region you want to cover on the map, also you can use `Edit layers` button and `Delete layers` button to modify your flight region. When finished with selecting region, clik `Finish` to update and display flight route on the map.

4. **Table**
 - Shows latitude, longitude, altitude, heading, curvesize and other paramters of each waypoint.

5. **Summary**
 - Shows `Flight distance`, `Flight speed` and `Flight duration` of the flight mission. 
 - Click `Download waypoints` button to download waypoint imformation to your device as .csv file.

### Generate flight mission

1. Go to [Litchi Mission Hub](https://flylitchi.com/hub).
2. Go to `MISSIONS` > `import` to import your downloaded waypoint file(.csv file). when imported, waypoints and flight route will be displayed on the map.
3. Go to `MISSIONS` > `save` to save the flight mission and the flight mission will be synced to your mobile device (need a Litchi account).
4. Open Litchi app in your mobile device, and select waypoint mode to load your mission (need a Litchi account).
5. Enjoy!
