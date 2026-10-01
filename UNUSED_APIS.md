# Unused APIs

Endpoints in `lib/features/auth/data/swagger.json` that the app does not call yet
(admin/dashboard routes are excluded).

## Customer

| Method | Path | Note |
| --- | --- | --- |
| GET | `/api/customer/notifications` | Endpoint is defined, but the notifications data source still uses mock data |
| PUT | `/api/customer/profile/password` | No change-password screen yet |

## Driver

| Method | Path | Note |
| --- | --- | --- |
| POST | `/api/driver/auth/signup` | Only the driver sign-in screen exists |
| POST | `/api/driver/rides/{id}/accept` | Accepting goes through the socket event `driver:order_accept` |
| POST | `/api/driver/rides/{id}/pickup` | "Arrived at pickup" step not wired up |
| POST | `/api/driver/rides/{id}/start` | "Start trip" step not wired up |
| POST | `/api/driver/rides/{id}/finish` | "Finish trip" step not wired up |

## Other

| Method | Path | Note |
| --- | --- | --- |
| GET | `/` | Health check |
