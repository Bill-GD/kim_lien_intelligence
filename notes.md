# Notes

- Shortcut:
  - `KeyboardListener`
    - requires `FocusNode`, has `onKeyEvent` callback
    - loses focus if clicked on floating action (or other buttons too idrk)
  - `CallbackShortcut`
    - requires `Focus` child (no `FocusNode`), callbacks are mapped to `ShortcutActivator` (`bindings`)
    - loses focus if use `DropdownMenu`
  - `Shortcuts`
    - requires custom `Intent` classes, `Focus`
    - activates when using `DropdownMenu` or `Button`
    - very rarely -> doesn't work -> tab -> focus -> work again