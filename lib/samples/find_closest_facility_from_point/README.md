# Find closest facility from point

Find routes from several locations to the respective closest facility.

![Image of find closest facility from point](find_closest_facility_from_point.png)

## Use case

Quickly and accurately determining the most efficient route between a location and a facility is a frequently encountered task. For example, a city's fire department may need to know which firestations in the vicinity offer the quickest routes to multiple fires. Solving for the closest fire station to the fire's location using an impedance of "travel time" would provide this information.

## How to use the sample

Tap on 'Solve Routes' button to solve and display the route from each incident (fire) to the nearest facility (fire station).

## How it works

1. Create a `ClosestFacilityTask` using a URL from an online service.
2. Get the default set of `ClosestFacilityParameters` from the task: `closestFacilityTask.createDefaultParameters()`.
3. Create feature layers for the `Facilities` and `Incidents`:
  * Create a `FeatureTable` using `ServiceFeatureTable.withUri(Uri)`.
  * Query the `FeatureTable` for all `Features` using `FeatureLayer.withFeatureTable(featureTable)`.
  * Add the `Facilities` and `Incidents` layers to the map.
4. Add a list of all facilities to the task parameters: `closestFacilityParameters.setFacilitiesWithFeatureTable(facilitiesList)`.
5. Add a list of all incidents to the task parameters: `closestFacilityParameters.setIncidentsWithFeatureTable(incidentsList)`.
6. Get `ClosestFacilityResult` by solving the task with the provided parameters: `closestFacilityTask.solveClosestFacility(closestFacilityParameters)`.
7. Find the closest facility for each incident by iterating over the list of `results.incidents`s.
8. Display the route as a `Graphic` using the `routeGraphicsOverlay.graphics.add(routeGraphic)`.

## Relevant API

* ClosestFacilityParameters
* ClosestFacilityResult
* ClosestFacilityRoute
* ClosestFacilityTask
* Facility
* Graphic
* GraphicsOverlay
* Incident

## Tags

incident, network analysis, route, search
