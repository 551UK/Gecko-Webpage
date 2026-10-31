# Write Now Gecko Companion (experimental)

Standalone rootless helper for Write Now 2.4, to show its original rewriting UI inside editable Gecko webpage fields in Reynard Browser and the custom ChatGPT app. Leaves both existing apps and Write Now untouched.

Captures the current selection via Gecko UITextInput, opens Write Now with a temporary native UITextView, and forwards applied edits to Gecko only if the original text remains unchanged.

**Untested on-device**. Try with Google search first; uninstall the companion if selection or rewriting fails. No license modification is included.
