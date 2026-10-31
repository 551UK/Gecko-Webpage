# Gecko-Webpage v0.1.0 — experimental

Gecko-based fullscreen web app for older iOS versions, particularly where official apps may be unsupported or limited. It can mimic the app-like experience of sites such as eBay, ChatGPT, Discord and Google using their websites.

### Features
- Fullscreen Gecko website display (based on Reynard 0.19.0; not WebKit).
- **Change Website** Home Screen icon long-press action: opens an in-app URL prompt and saves your homepage.
- **Start New Session** Home Screen long-press action: immediately opens the chosen homepage, without deleting logins/cookies.
- Normal app opening restores the last browsing session.
- Four separately installable instances, each with its own bundle identifier and browsing data.
- Slim package retains core Gecko libraries while trimming optional localisation/hyphenation files.

### Downloads
- `Gecko-Webpage-1.ipa` — `com.551uk.gwa.kiosk1` (Gecko WebApp 1)
- `Gecko-Webpage-2.ipa` — `com.551uk.gwa.kiosk2` (Gecko WebApp 2)
- `Gecko-Webpage-3.ipa` — `com.551uk.gwa.kiosk3` (Gecko WebApp 3)
- `Gecko-Webpage-4.ipa` — `com.551uk.gwa.kiosk4` (Gecko WebApp 4)
- Source and build files are available in the [repository](https://github.com/551UK/Gecko-Webpage/tree/main/src).

### Warnings
**Experimental and unsigned.** The runtime and IPA structure are compiled/validated in CI, but an actual iPhone test has not yet verified launch, callback handling and full-screen behaviour. Back up anything important before installing. Built from upstream Reynard 0.19.0 jailbroken IPA; inherited entitlements can affect Apps Manager visibility.

Credits: [Reynard Browser](https://github.com/minh-ton/reynard-browser), GPL-3.0. Source changes are available in this repository.
