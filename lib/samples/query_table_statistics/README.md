# Query table statistics

Query a table to get aggregated statistics back for a specific field.

![Image of query table statistics](query_table_statistics.png)

## Use case

For example, a county boundaries table with population information can be queried to return aggregated results for the total, average, maximum, and minimum population, rather than downloading the values for every county and calculating the statistics manually.

## How to use the sample

Pan and zoom to define the extent for the query. In the Settings panel, use the 'Only cities in current extent' checkbox to control whether the query includes only features in the visible extent, or use the 'Only cities greater than 5M' checkbox to filter the results to only those cities with a population greater than 5 million people. Tap the 'Get statistics' to perform the query. The query will return population-based statistics from the combined results of all features matching the query criteria.

## How it works

1. Create a `ServiceFeatureTable` with a URL to the feature service.
2. Create `StatisticsQueryParameters`, and `StatisticDefinition` objects, and add to the parameters.
3. Execute `queryStatistics` on the `ServiceFeatureTable`. Depending on the state of the two checkboxes, additional parameters are set.
4. Display each `StatisticRecord` in the first returned `QueryStatisticsResult`.

## Relevant API

* QueryParameters
* ServiceFeatureTable
* StatisticDefinition
* StatisticRecord
* StatisticsQueryParameters
* StatisticsQueryResult
* StatisticType

## Tags

analysis, average, bounding geometry, filter, intersect, maximum, mean, minimum, query, spatial query, standard deviation, statistics, sum, variance
