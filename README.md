# Market.io — 3D Pizza Tycoon

A mobile-first, third-person 3D pizza-shop management game built with Godot 4.

## Play loop

- Explore a warm, stylized 3D pizzeria with a controllable character and follow camera.
- Start with one brick pizza oven, a prep counter, a serving counter, and **$65**.
- Walk close to the oven and tap **Cook Pizza** to spend $5 on ingredients.
- Walk to the counter and tap **Serve Customer** to sell a pizza for $14.
- Reinvest earnings to unlock dining tables and extra ovens, then hire workers who automate serving.
- Touch movement controls are included for Android, with keyboard support for desktop testing.

## Build locally

Open the repository in Godot 4.4.x or later, then run `main.tscn`.

## Android APK

Every push to `main` and every manual workflow dispatch runs the **Market.io Android Build** workflow. It validates the Godot project, exports an Android debug APK, and uploads `Market.io-Android-APK` as a downloadable workflow artifact.

1. Open the repository's **Actions** tab.
2. Select **Market.io Android Build**.
3. Open the latest successful run and download **Market.io-Android-APK**.

The debug APK is for testing. Google Play publication requires release signing, an Android App Bundle (AAB), store listing assets, policy checks, and Play Console review. Keep signing keys and passwords in GitHub Actions secrets; never commit them.

## Current scope

This is a playable foundation, not a claim of store-ready production quality. Save/load, audio, richer animations, additional rooms, expanded staff AI, device testing, and a signed release pipeline remain future milestones.
