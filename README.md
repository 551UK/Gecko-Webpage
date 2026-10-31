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

## Multiple instances

Four separate Gecko-Webpage IPAs are available in [Releases](https://github.com/551UK/Gecko-Webpage/releases), each with a different bundle ID. You can install them side by side as **Gecko WebApp 1, 2, 3 and 4**, with separate browsing sessions for each.

You can also use compatible iOS tweaks to **change each app's Home Screen icon and displayed name**, helping it resemble the native app for that website (for example, eBay or Discord). This changes its appearance, not the website's functionality.
