# Gecko-Webpage v0.2.1 — runtime Unknown Protocol recovery

Experimental Gecko-based standalone website app using Reynard 0.19.0.

## What's new
- Detect **Unknown Protocol** error screens while browsing, not just during launch.
- Where Reynard's native Back control is available, try that first so the user stays on the previous website.
- If the error remains, automatically open this instance's saved homepage; protect against repeat-trigger loops for the same error presentation.
- Only this specific error triggers the recovery; SSL, certificate, offline, and ordinary website errors are unchanged.
- Preserve the four independent bundle IDs and separate cookies/logins; no app data is wiped.

## Retained from v0.2.0
- Fullscreen hidden-toolbar and zero-bottom-height fixes.
- Hidden native controls no longer intercept touches.
- Targeted startup recovery from unsupported saved schemes and the reported Reddit ad redirect.
- Last-session restoration and the two original Home Screen long-press shortcuts.

## Four unsigned IPAs
- `Gecko-Webpage-1.ipa` — `com.551uk.gwa.kiosk1`
- `Gecko-Webpage-2.ipa` — `com.551uk.gwa.kiosk2`
- `Gecko-Webpage-3.ipa` — `com.551uk.gwa.kiosk3`
- `Gecko-Webpage-4.ipa` — `com.551uk.gwa.kiosk4`

**Testing:** Built and ZIP-structure validated in GitHub Actions. Runtime recovery relies on Reynard 0.19.0's native error view and must still be checked on a real iPhone. An optional Swift private-ivar Back handler is guarded by runtime checks; homepage recovery is the fallback. The apps are unsigned and intended for compatible signing/installation workflows.
