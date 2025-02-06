# Show device location with NMEA data sources

Parse NMEA sentences and use the results to show device location on the map.

![Image of show device location with NMEA data sources](show_device_location_with_nmea_data_sources.png)

## Use case

NMEA sentences can be retrieved from GPS receivers and parsed into a series of coordinates with additional information. Devices without a built-in GPS receiver can retrieve NMEA sentences by using a separate GPS dongle, commonly connected bluetooth or through a serial port.

The NMEA location data source allows for detailed interrogation of the information coming from the GPS receiver. For example, allowing you to report the number of satellites in view.

## How to use the sample

Tap the "Start" button to start a simulated NMEA data provider and the `NmeaLocationDataSource`. Tap "Recenter" to recenter the location display. Tap "Reset" to reset the location display.

## How it works

1. A simulated NMEA data source parses an NMEA string into sentences and provides that data as a stream.
2. Create a `NmeaLocationDataSource` and push the NMEA sentences from the stream with `NmeaLocationDataSource.push()`.
3. Set the `NmeaLocationDataSource` to the location display's data source.
4. Start the location data source to begin receiving location and satellite updates.

## Relevant API

* AGSLocation
* AGSLocationDisplay
* AGSNMEALocationDataSource
* AGSNMEASatelliteInfo

## About the data

A string of NMEA sentences is used to initialize a `SimulatedNmeaDataSource` object. This simulated data source provides NMEA data periodically, and allows the sample to be used on devices without a GPS dongle that produces NMEA data.

The route taken in this sample features a [2-minute driving trip around Redlands, CA](https://arcgis.com/home/item.html?id=d5bad9f4fee9483791e405880fb466da).

## Additional information

Below is a list of protocol strings for commonly used GNSS external accessories. Please refer to the [ArcGIS Field Maps documentation](https://doc.arcgis.com/en/field-maps/ios/help/high-accuracy-data-collection.htm#ESRI_SECTION2_612D328A655644DCAF5CF0210308C821) for model and firmware requirements.

* com.amanenterprises.nmeasource
* com.bad-elf.gps
* com.dualav.xgps150
* com.eos-gnss.positioningsource
* com.garmin.pvt
* com.geneq.sxbluegpssource
* com.junipersys.geode
* com.leica-geosystems.zeno.gnss
* com.searanllc.serial
* com.trimble.correction, com.trimble.command (1)

(1) Some Trimble models requires a proprietary SDK for NMEA output.

## Tags

dongle, GPS, history, navigation, NMEA, real-time, trace
