# Find closest facility from point

Find routes from several locations to the respective closest facility.

![Image of find closest facility from point](find_closest_facility_from_point.png)

## Use case

Quickly and accurately determining the most efficient route between a location and a facility is a frequently encountered task. For example, a city's fire department may need to know which firestations in the vicinity offer the quickest routes to multiple fires. Solving for the closest fire station to the fire's location using an impedance of "travel time" would provide this information.

## How to use the sample

Tap on the 'Solve Routes' button to solve and display the route from each incident (fire) to the nearest facility (fire station).

## How it works

1. Create a `ClosestFacilityTask` using a URL from an online service.
2. Create a `FeatureTable` for each of the `Facilities` and `Incidents` services using `ServiceFeatureTable.withUri(uri)`.
3. Get the default set of `ClosestFacilityParameters` from the task using `ClosestFacilityTask.createDefaultParameters()`.
4. Add the facilities table to the task parameters, along with `QueryParameters` defined to query all features using `ClosestFacilityParameters.setFacilitiesWithFeatureTable(featureTable, queryParameters)`.
5. Add the incidents table to the task parameters, along with `QueryParameters` defined to query all features using `ClosestFacilityParameters.setIncidentsWithFeatureTable(featureTable, queryParameters)`.
6. Get the `ClosestFacilityResult` by solving the task with the provided parameters: `ClosestFacilityTask.solveClosestFacility(closestFacilityParameters)`.
7. Find the closest facility for each incident by iterating over the list of `result.incidents`.
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
