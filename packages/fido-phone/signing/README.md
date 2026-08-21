# APK signing policy

The key in this directory is deliberately public and unencrypted. It provides
a stable Android package identity so personal APK builds can update the
existing installation; it is not treated as a secret or an authorization
boundary.

Anyone can use this key to produce an APK that Android recognizes as an update
to the same app. That tradeoff is accepted only because installation and
updates remain personally controlled; this key must not be reused for a
distributed app.
