(defsrc
  ;; Define intercepted physical keys. Order determines layer mapping.
  ;; 1    2    3   4   5   6   7   8   9   10  11  12  13  14
  esc    caps  a   s   d   f   e   h   j   k   l   ;   o   spc
)

(defvar
  tap-timeout   220
  hold-timeout  240 ;; (>= tap-timeout)
  combo-timeout 50  ;; Chord detection window
  toggle-hold-time 500 ;; Hold duration for 'o' layer toggle

  ;; Keys that resolve left-hand mods (a,s,d,f) as TAP early.
  ;; Used by `tap-hold-release-keys` for better rolling performance.
  left-hand-keys (
    q w e r t
    a s d f g
    z x c v b
  )

  ;; Keys originally intended for early TAP resolution on right-hand mods.
  ;; Less critical now as j,k,l,; use basic `tap-hold`, but retained.
  right-hand-keys (
    y u i o p
    h j k l ;
    n m , . /    
  )
)

;; Bilateral Combinations aka (Chords) aka (Combos)
(defchordsv2
  ;; Keys  Action Timeout Behavior                Disabled-Layers
  (a s)    bspc   $combo-timeout first-release () ;; Left index-middle -> Backspace
  (s d)    del    $combo-timeout first-release () ;; Left middle-ring  -> Delete
  (k l)    ret    $combo-timeout first-release () ;; Right middle-ring -> Enter
  (j k)    tab    $combo-timeout first-release () ;; Right index-middle-> Tab
)

;; Layers
(deflayer base
  ;; Default layer: Home Row Mods (HRMs) active. Spacebar uses @spc-nav.
  caps   esc   @a  @s  @d  @f  e   h   @j  @k  @l  @;  @o-mods-on  @spc-nav
)

(deflayer base-no-mods
  ;; Base layer variant: HRMs toggled OFF via 'o'. Spacebar uses @spc-nav.
  caps   esc   a   s   d   f   e   h   j   k   l   ;   @o-mods-off @spc-nav
)

(deflayer arrow-layer
  ;; Arrow Navigation layer: Active while Space (@spc-nav) is HELD.
  ;; Maps HJKL to arrows. Underscores `_` denote transparency, passing keys
  ;; through to the underlying layer (e.g., allows holding 'd' for Ctrl + Arrow).
  _      _     _   _   _   _   _   left down up right _   _   _
)

;; Key behavior aliases (mod-taps, layer switching, etc.)
(defalias
  ;; Left Hand HRMs: Meta, Alt, Ctrl, Shift
  ;; Using `tap-hold-release-keys` with $left-hand-keys for improved tap
  ;; responsiveness during common typing rolls (e.g., `f`+`spc`).
  a (tap-hold-release-keys $tap-timeout $hold-timeout a lmet $left-hand-keys)
  s (tap-hold-release-keys $tap-timeout $hold-timeout s lalt $left-hand-keys)
  d (tap-hold-release-keys $tap-timeout $hold-timeout d lctl $left-hand-keys)
  f (tap-hold-release-keys $tap-timeout $hold-timeout f lsft $left-hand-keys)

  ;; Right Hand HRMs: Shift, Ctrl, Alt, Meta
  ;; Using standard `tap-hold` for robust modifier behavior, prioritizing
  ;; reliable mod activation over potential tap-speed gains on rolls.
  j (tap-hold $tap-timeout $hold-timeout j rsft)
  k (tap-hold $tap-timeout $hold-timeout k rctl)
  l (tap-hold $tap-timeout $hold-timeout l ralt)
  ; (tap-hold $tap-timeout $hold-timeout ; rmet)

  ;; Spacebar: Tap for Space, Hold for arrow-layer activation
  spc-nav (tap-hold $tap-timeout $hold-timeout spc (layer-while-held arrow-layer))

  ;; 'o' Key: Tap for 'o', Hold ($toggle-hold-time) to toggle HRM layer.
  o-mods-on  (tap-hold $tap-timeout $toggle-hold-time o (layer-switch base-no-mods)) ;; Turns mods OFF
  o-mods-off (tap-hold $tap-timeout $toggle-hold-time o (layer-switch base))         ;; Turns mods ON
)
