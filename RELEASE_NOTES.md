# Gecko-Webpage v0.1.0 — experimental

Gecko-based fullscreen web app for older iOS versions, particularly where official apps may be unsupported or limited. It can mimic the app-like experience of sites such as eBay, ChatGPT, Discord and Google using their websites.

### Features
- Fullscreen Gecko website display (based on Reynard 0.19.0; not WebKit).
- **Change Website** Home Screen icon long-press action: opens an in-app URL prompt and saves your homepage.
- **Start New Session** Home Screen long-press action: immediately opens the chosen homepage, without deleting logins/cookies.
- Normal app opening restores the last browsing session.
- Source/clone kit supports multiple installed instances with unique bundle identifiers and optional custom icons.
- Slim package retains core Gecko libraries while trimming optional localisation/hyphenation files.

### Downloads
- `Gecko-Webpage-v0.1.0-TrollStore-UNSIGNED.ipa` — experimental Gecko WebApp for compatible TrollStore installations.
- `Gecko-Webpage-v0.1.0-Clone-Kit.zip` — source, IPA clone/packer script and compiled arm64 iOS extension.

### Warnings
**Experimental and unsigned.** The runtime and IPA structure are compiled/validated in CI, but an actual iPhone test has not yet verified launch, callback handling and full-screen behaviour. Back up anything important before installing. Built from upstream Reynard 0.19.0 jailbroken IPA; inherited entitlements can affect Apps Manager visibility.

Credits: [Reynard Browser](https://github.com/minh-ton/reynard-browser), GPL-3.0. Source changes are available in this repository.
