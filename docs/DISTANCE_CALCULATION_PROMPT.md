# Prompt: How distance (From → To) is calculated today, for Dashboard + Backend

## Context

The Flutter apps (customer + driver) and the backend measure distance in **three different ways**. The route drawn on the map is a correct road route, and the current distances are good enough to ship for now. This file explains exactly what Flutter does today, so the dashboard and backend show and use the same numbers, and so you know what could be improved later.

## What Flutter does today

### 1. Order time (customer picks From → To): NOT done in Flutter
- Flutter only sends the pickup/dropoff coordinates to `POST /api/customer/rides/locations`.
- The **server** returns `distance_km` and the estimated prices. Per swagger, this is a **straight-line Haversine** distance. Swagger says: "These prices are not final — they use straight-line distance."
- Same for the dashboard quote: `POST /api/admin/orders/quote` returns `distance_km` (also straight-line).
- Formula used by the server: `estimated_price = base_fare + distance_km × price_per_km`.

### 2. Road route on the map: OSRM, drawing only
- File: `lib/core/services/route_service.dart`
- Calls OSRM: `GET https://router.project-osrm.org/route/v1/driving/{fromLng},{fromLat};{toLng},{toLat}?overview=full&geometries=geojson`
- We only read `routes[0].geometry.coordinates` to **draw the planned line** (pickup → dropoff) on the map.
- We **do not read** OSRM's `routes[0].distance` (meters) or `routes[0].duration` (seconds). That is the real road distance, and it is already in the same response. It is simply unused.
- The URL is the public OSRM demo server (`AppConstants.routingBaseUrl`). It is for development only and needs a self-hosted OSRM for production.

### 3. During the trip (driver app): GPS accumulation, this is the "real" distance
- Files: `lib/driver_features/driver_trip/presentation/cubit/driver_trip_cubit.dart`, `.../datasources/driver_trip_location_service.dart`
- The driver app streams GPS positions (`Geolocator.getPositionStream`, `distanceFilter = 5 m`).
- For each new fix, it adds `Geolocator.distanceBetween(previousFix, newFix)` to a running total. That is a geodesic (Haversine-like) distance **between consecutive real GPS points**.
- Fixes with `accuracy > 100 m` are ignored.
- Because the points follow the road the driver actually took, the sum approximates the real driven route, even though each tiny segment is a straight line.
- At finish, the app sends `POST /api/driver/rides/{id}/finish` with `{ "distance_km": <total, 2 decimals> }`. The server recalculates the **final fare** from this value.
- If GPS never produced a usable fix, the app falls back to the quoted `distance_km`, because the server rejects 0.
- Route resume: if the app is killed mid-trip, `RouteDistanceCalculator` (`lib/driver_features/driver_trip/data/route_distance_calculator.dart`) rebuilds the total by summing straight-line gaps between the saved 5-second samples. This slightly under-measures winding roads.

### 4. Driven route upload
- Every ~5 s the driver app records `{lat, lng, recorded_at}`.
- After finish, it uploads them with `PUT /api/driver/rides/{id}/route`.
- The server computes its own `route_distance_km` from those points (Haversine sum).
- Ride objects expose: `distance_km` (estimate), `actual_distance_km` (driver-reported), `route_distance_km` (server-computed from the uploaded points), `has_route`, `route`.

## Summary

| Moment | Source | Type | Status |
|---|---|---|---|
| Order quote (From → To) | Backend | Straight-line Haversine | Works for now, an estimate that can be lower than the road distance |
| Planned map line | OSRM (Flutter) | Real road geometry | Correct |
| Final fare | Driver GPS sum | Sum of GPS segments | Approximately the real driven distance |

The quote is labelled as an estimate, and the final fare is recalculated from the driven distance at finish. So a small difference between the quote and the final price is expected.

## What I need from you (Dashboard + Backend)

**Now (no big change needed):**
1. Keep returning `distance_km` with the same name and type. Flutter already reads it.
2. **Dashboard:** when showing a completed order, show the estimated `distance_km`, `actual_distance_km` and `route_distance_km`, and draw `route` (use `?simplify=true` on the detail endpoint). Flag orders where `actual_distance_km` and `route_distance_km` differ a lot, because the driver reports `distance_km` themselves.
3. Tell us which distance the dashboard should treat as the official one: the driver-reported `distance_km` (current behavior) or the server-computed `route_distance_km`. The second is harder to cheat, but the route upload happens after finish and can fail or arrive late (72 h window).

**Later (optional improvement):**
- Make the quote distance a real road distance. Option: backend calls OSRM and uses `routes[0].distance` (meters) and `routes[0].duration` (seconds); this is also in the response Flutter already fetches for drawing. Keep Haversine as a fallback.
- If you do this, self-host OSRM. The public demo server (`router.project-osrm.org`) has no SLA and is rate-limited, so it is for development only.
- Optionally return `distance_source: "road" | "straight_line"` so the apps and dashboard know which one they got.
