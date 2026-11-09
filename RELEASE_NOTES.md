# Gecko-Webpage v0.2.0 — fullscreen and session fixes

Gecko-based standalone website app using Reynard 0.19.0, designed for older iOS versions.

## Changes
- Prevent hidden address bars, browser overlays and their gestures from intercepting taps.
- Return the invisible bottom toolbar's height as zero and disable dynamic scroll-to-hide toolbar insets.
- Reapply edge-to-edge webpage layout after Reynard changes its native view constraints.
- On launch, recover from a selected saved tab containing an unsupported URL scheme or the Reddit `dhan.go.link?rdt_cid=` ad redirect. The affected tab is sent to the configured homepage.
- Remove other saved regular tabs matching that **specific reported ad redirect**; do not clear general browsing data.
- Preserve normal last-tab restoration, valid tabs, sessions, cookies, logins, and the original two Home Screen quick actions.
- Retain four independently installable app instances, each with its own bundle ID and container.

## Four unsigned IPAs
- `Gecko-Webpage-1.ipa` — `com.551uk.gwa.kiosk1`
- `Gecko-Webpage-2.ipa` — `com.551uk.gwa.kiosk2`
- `Gecko-Webpage-3.ipa` — `com.551uk.gwa.kiosk3`
- `Gecko-Webpage-4.ipa` — `com.551uk.gwa.kiosk4`

Source and build scripts: [Gecko-Webpage](https://github.com/551UK/Gecko-Webpage/tree/main/src).

**Experimental / unsigned:** GitHub Actions compiles and checks IPA structure; behaviour still requires testing on a compatible jailbroken iPhone or TrollStore-enabled device. No default forced GPU/JIT or site-specific Gemini CSS tweaks are included: those could cause instability or break other websites.
