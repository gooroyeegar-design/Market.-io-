# Market.io

A stylized third-person 3D shop-management game for Android.

Start with a tiny store, restock products, serve customers, earn cash, and grow toward a business empire.

## Current prototype

- Procedurally built 3D shop, shelves, products, checkout, lighting, and a third-person camera.
- Controllable player with keyboard and touch-friendly movement controls.
- Customers browse and purchase products when stock is available.
- Restocking costs money; sales add cash.
- On-screen cash, inventory, sales, and customer counters.
- Mobile-friendly GL Compatibility renderer.

## Build

Open the project in Godot 4.4.x and run main.tscn.

The GitHub Actions workflow checks the project and attempts an Android debug APK export. A Google Play release requires an Android App Bundle (AAB), a release signing key, store listing assets, and Play Console review. Never commit a keystore or signing passwords. Those must be configured as GitHub Actions secrets before a signed release can be produced.

## Planned next milestones

1. Verify Android build and improve touch controls.
2. Add shelf restock animations, product pickup/placement, employee hiring, and store expansion.
3. Add save/load, sound, settings, pause menu, and device-performance testing.
4. Configure a signed AAB build and complete Google Play compliance checks.
