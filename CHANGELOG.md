## 0.2.0

- Render month headers, weekday labels, and compatible day cells on Canvas in month and week views. Custom widget cells keep their layout, interaction, and accessibility support.
- Add optional `CalendarMarker.data` for application objects and `CalendarMarkerIndex` for pre-indexed marker collections. Classes that implement `CalendarMarker` directly should add the `Object? data` getter.
- Add the Holiday Lights demo with animated festivals and all 24 solar terms, plus browser previews and an Android demo APK on GitHub Releases.
- Add regression tests for mixed Canvas and widget cells, large marker collections, and holiday animations, plus real-device benchmark results.

## 0.1.0

Initial public release.

- Added reusable calendar core APIs.
- Added month and week display modes.
- Added single, range, and multi-selection support.
- Added date bounds, disabled dates, and marker data.
- Added year view and month-year interactive layout.
- Added pluggable `CalendarComponentBuilder` styling protocol.
- Added demo styles and bilingual API documentation.
