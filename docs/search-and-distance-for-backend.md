# How place search, routes and distance work in the customer app

**For:** backend team. **Scope:** what the Flutter app does on its side, what it sends to our API, and one thing we need from the backend.

## TL;DR

- **Place search, address lookup and route drawing are done entirely in the app, directly against Google.** The backend has no search or geocoding endpoint and is not involved.
- The backend only receives **coordinates and the address text** when the customer asks for a quote or orders a ride.
- **The `distance_km` returned by `POST /api/customer/rides/locations` is a straight line (Haversine), so it is too short on real roads.** Example: دوار هارون → صلنفة shows **35.8 km**; the road is **40+ km**. The price is built from the same number, so fares are under-estimated on winding routes. See [What we need from the backend](#what-we-need-from-the-backend).

---

## 1. Place search (typing a name)

Google **Places API (New) – Text Search**, called from the app with its own plain HTTP client (the user's login token is never sent to Google).

| | |
|---|---|
| Request | `POST https://places.googleapis.com/v1/places:searchText` |
| Body | `textQuery`, `languageCode: "ar"`, `regionCode: "SY"`, `locationBias` = a box around Latakia, `pageSize: 8` |
| Fields asked | `displayName`, `formattedAddress`, `location` only |
| When | 400 ms after the customer stops typing (debounce) |

Result handling in the app:

1. Places with no coordinates are dropped. Duplicates are dropped.
2. Each suggestion is shown as `name، cleaned address` (the plus code prefix such as `X258+GH3،` and the trailing `، سوريا` are removed).
3. **Order shown:** Latakia first, then the rest of Syria, then anywhere else. Inside each group, results that match the typed words come first, then the nearest to the customer's GPS position (straight-line distance on the device).
4. Picking a suggestion moves the map pin to its coordinates. No second "place details" call is needed.

If Google is unreachable, the key is refused, or there is no key, the app shows a search error. There is no fallback provider.

## 2. Naming a dropped pin (reverse geocoding)

When the customer drags the map or taps the GPS button, the app turns the pin's coordinates into an address:

- Google **Geocoding API**: `GET https://maps.googleapis.com/maps/api/geocode/json?latlng=<lat>,<lng>&language=ar`
- Results that are only a plus code are skipped; the first real address is used and cleaned the same way as above.
- If nothing is found, the pin keeps no address and the app displays raw coordinates (5 decimals) as its label.

## 3. Route line on the map, ETA and driven distance

- **Road line, distance and ETA on the tracking maps:** Google **Routes API** (`POST https://routes.googleapis.com/directions/v2:computeRoutes`, `DRIVE`, traffic-aware). Used by both the customer tracking screen and the driver trip screen to draw the road from pickup to dropoff and the driver to pickup.
- **Distance driven during a trip (driver app):** summed GPS fixes on the device (straight-line gaps between consecutive samples).

None of these values come from, or are sent back as authoritative data to, the backend search flow.

All Google calls use the single `GOOGLE_MAPS_API_KEY` from the app's `.env`.

## 4. What the app sends to our API

Quote — `POST /api/customer/rides/locations` (same fields are sent again to `POST /api/customer/rides/choose-vehicle`):

```json
{
  "pickup_lat": 35.52,
  "pickup_lng": 35.79,
  "pickup_address": "دوار هارون، اللاذقية",
  "pickup_address_details": "optional, typed by the customer (building, floor, landmark)",
  "dropoff_lat": 35.59,
  "dropoff_lng": 36.16,
  "dropoff_address": "صلنفة",
  "dropoff_address_details": "optional"
}
```

- `*_address` is the Google text described above (Arabic). It can be absent if the lookup failed.
- `*_address_details` is free text from the customer and is only sent when filled in.
- The app displays `distance_km`, `estimated_duration_min` and the per-vehicle `estimated_price` exactly as returned.

## What we need from the backend

**Problem:** per the API docs, `POST /api/customer/rides/locations` computes `distance_km` and the ETA as **Haversine (straight-line)** distance, and `estimated_price = base_fare + distance_km × price_per_km` from it. The app just shows it.

**Example:** دوار هارون → صلنفة returns **35.8 km**; the real road distance is **40+ km** (mountain road with many bends). The customer sees a short distance and a low estimate, and the final fare can differ from the quote.

**Request:** compute `distance_km`, `estimated_duration_min` and the estimated price from the **road distance** instead of the straight line, for example with the Google Routes API (`computeRoutes`, `DRIVE`) or a similar routing service. This keeps the distance shown, the ETA and the price consistent, and the app needs no change as long as the response fields keep the same names.

If the backend would rather not call a routing service, an alternative is for the app to send the road distance it already knows from Google Routes and for the backend to price on it. That means a new optional request field and the backend trusting a client value, so we prefer the first option. Please tell us which you choose.

## Reference (app code)

| What | File |
|---|---|
| Google place search + reverse geocoding | `lib/features/home/data/datasources/google_places_data_source.dart` |
| Search orchestration and ranking | `lib/features/home/data/repositories/places_repository.dart`, `lib/features/home/data/place_search_ranker.dart` |
| Google Routes (road line, distance, ETA) | `lib/core/services/google_routes_service.dart` |
| Quote request body | `lib/features/home/data/datasources/ride_request_remote_data_source.dart` |
