# Gecko-Webpage

**Gecko-Webpage** turns websites into separate, fullscreen iPhone apps using the **Firefox Gecko engine** (via [Reynard Browser](https://github.com/minh-ton/reynard-browser)), instead of Safari's WebKit.

It is especially useful on **older iOS versions**, where official apps may no longer be supported, are missing features, or cannot run updated versions. Rather than replacing the original native apps, Gecko-Webpage helps you **mimic the experience of an app** by opening its website directly as an app-like fullscreen window. Examples include eBay, Google, Discord and ChatGPT (subject to the website's own functionality and compatibility). **Website functionality may differ from the original native app.**

## What it does

- **Fullscreen website view:** Launches your configured website without the normal browser address bar, tabs or navigation toolbars.
- **Gecko engine:** Uses Reynard's Gecko browser engine rather than the older WebKit engine bundled with the iOS version.
- **Two Home Screen long-press (3D Touch / Haptic Touch) actions:**
  - **Change Website** — launches Gecko-Webpage and displays a URL prompt **inside the app**; entering a URL saves it as the homepage and opens it.
  - **Start New Session** — launches the app directly to its saved homepage, even if you previously left it on another page. This does **not** erase cookies, account logins, or the browser history.
- **Automatic session restoration:** Opening the icon normally resumes the last browsing tab/page. You do not have to manually restore a session.
- **Independent clones:** By repackaging the IPA with a different bundle ID and optionally a custom icon, you can install multiple separate website apps side by side. Each correctly installed clone has its own data container/session.

The custom long-press options appear when you **press and hold the app icon on the iPhone Home Screen**. There is no hidden three-finger gesture or in-app browser settings menu. iOS may also show its own standard Home Screen actions.

## Screenshots / example

For example, clone Gecko-Webpage as `eBay`, set `https://www.ebay.co.uk` as its homepage and use a custom eBay-style icon. It appears on the Home Screen like an app and opens the eBay website using Gecko without normal Reynard browser controls. You can create more clones for other sites by assigning unique bundle IDs.

## Download and installation

Download the experimental **Gecko-Webpage IPA** from [Releases](https://github.com/551UK/Gecko-Webpage/releases) and install using TrollStore on a **compatible** iOS version. The packaged executable is an unsigned, modified Reynard 0.19.0 jailbroken build. It may need compatible JIT/entitlements to run properly and **has not yet been verified to launch and behave correctly on a real device**.

- Base browser: [Reynard 0.19.0](https://github.com/minh-ton/reynard-browser/releases/tag/0.19.0).
- Suitable for older iOS devices with supported installation methods; **not** a universal App Store-compatible IPA.
- This project is experimental. Keep a backup of an existing working installation and any important browsing data.

### How to use

1. Install the IPA with TrollStore.
2. Open the app normally to continue your previously saved page (initially set to Google).
3. Long-press the **app icon on the Home Screen** and select **Change Website** to set another homepage. The input box appears **after the app opens**.
4. Long-press and select **Start New Session** to go straight to that saved homepage.
5. Optionally create independently installed copies using the included cloning script.

## Clone the IPA / change its icon

The `src/build_gecko_kiosk.py` builder generates another IPA from an **original Reynard 0.19.0 jailbroken IPA** and the compiled `GeckoKiosk.dylib` runtime. Python 3 and Pillow are required:

```sh
python3 -m pip install Pillow
python3 src/build_gecko_kiosk.py \
  --ipa Reynard-Jailbroken.ipa \
  --dylib GeckoKiosk.dylib \
  --name "eBay" \
  --url "https://www.ebay.co.uk" \
  --icon ebay-icon.png \
  --id ebay01 \
  --output eBay-Gecko-Webpage.ipa
```

`--icon` is optional, and `--id` must be **six lowercase letters or digits**; choose a different ID for every clone to give each copy a unique bundle identifier. Repackaging changes the app identifier and bundled helper identifiers, not just the visible app name. The cloning kit shipped in Releases includes the same builder and the compiled arm64 runtime. Sign/install the resulting IPA with a compatible TrollStore setup.

## What was removed to reduce size

The slim build removes non-English Reynard interface localisations and non-English hyphenation dictionaries, along with unused alternate-icon assets. It **keeps** the Gecko engine, helper extensions, cryptographic/security libraries, PDF functionality and other core components. Some non-English UI and hyphenation functionality may be reduced. The source builder's `--no-slim` option can retain all language resources.

## Source code, credits and licence

- `src/GeckoKiosk.m` — custom fullscreen wrapper, session behaviour and Home Screen quick-action handlers.
- `src/build_gecko_kiosk.py` — packager and clone builder.
- `.github/workflows/build-and-release.yml` — compiles the custom arm64 iOS runtime and packages a release IPA using upstream Reynard 0.19.0.
- The actual Gecko browser engine and main application are from [Reynard Browser](https://github.com/minh-ton/reynard-browser). **This repository is not a full reimplementation of Gecko.**
- Reynard is GPL-3.0 licensed; see [the original source and licence](https://github.com/minh-ton/reynard-browser). Any distributions/derivatives must comply with the applicable open-source licences.

**Development status:** experimental; compile/archive tests are not substitutes for real-device verification. The two Home Screen actions and last-session behaviour should be tested on the target iOS device before considering this stable.
