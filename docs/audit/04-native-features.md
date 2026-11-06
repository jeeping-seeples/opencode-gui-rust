# Audit: Native and Platform Features Inventory (J-004)

## 1. Complete Native Desktop Feature Inventory

| Feature | Electron APIs Used | Upstream Source Path | Platform Specifics | Proposed Rust Route (Option) | Documentation Reference | Effort | Risk | Potential Loss / Caveats |
|---|---|---|---|---|---|---|---|---|
| Multi-Window Lifecycle | BrowserWindow, app.on('browser-window-created') | packages/desktop/src/main/windows/index.ts | Early window reveal differs on Windows vs macOS; Linux did-finish-load. | Tauri v2 WebviewWindow / WindowBuilder API (option) | https://v2.tauri.app/reference/javascript/api/namespacewebviewwindow/ | M | Low | Theme smoothing requires window show state control. |
| Window State Persistence | screen, BrowserWindow.getBounds, store | packages/desktop/src/main/windows/window-state.ts | Handles multiple monitors, display matching, maximized/fullscreen persistence. | tauri-plugin-window-state (option) or custom rusqlite | https://v2.tauri.app/plugin/window-state/ | S | Low | Direct SQLite/JSON mapping. |
| Custom Titlebar & Traffic Lights | BrowserWindow(titleBarStyle: 'hiddenInset', trafficLightPosition) | packages/desktop/src/main/windows/appearance.ts | macOS: traffic light insets; Windows/Linux: borderless with draggable titlebar. | Tauri window decorations API + wry windowButtonPosition (option) | https://v2.tauri.app/reference/javascript/api/namespacewindow/#setdecorations | M | Med | Traffic lights inset requires cocoa/objc2 on macOS if unexposed. |
| Application Menu & Shortcuts | Menu, Menu.buildFromTemplate, Menu.setApplicationMenu | packages/desktop/src/main/native/menu.ts | macOS has global menu bar; Windows/Linux auto-hides menu bar. | tauri-plugin-menu / tauri::menu (option) | https://v2.tauri.app/learn/window-menu/ | M | Low | Direct parity with Electron menu templates. |
| Single-Instance Lock | app.requestSingleInstanceLock(), app.on('second-instance') | packages/desktop/src/main/lifecycle/configure.ts | Passes command line args and deep links to first instance. | tauri-plugin-single-instance (option) | https://v2.tauri.app/plugin/single-instance/ | S | Low | Exact functional parity. |
| Deep Links & Custom Protocol | app.setAsDefaultProtocolClient('opencode') | packages/desktop/src/main/lifecycle/deep-link.ts | Registers opencode:// scheme across OSes. | tauri-plugin-deep-link (option) | https://v2.tauri.app/plugin/deep-link/ | M | Low | Handles auth callbacks and return links. |
| File & Directory Pickers | dialog.showOpenDialog, dialog.showSaveDialog | packages/desktop/src/main/files/picker.ts | Native OS file/folder selectors with filter options. | tauri-plugin-dialog (option) | https://v2.tauri.app/plugin/dialog/ | S | Low | Direct equivalent. |
| Security File Access Tokens | Crypto randomUUID, memory token budget | packages/desktop/src/main/files/attachment-picker.ts | Authorizes renderer reads of picked files via token. | Native Rust module in shell crate (option) | https://docs.rs/uuid/latest/uuid/ | S | Low | Trivial in Rust memory cache. |
| System Clipboard | clipboard.readImage, clipboard.writeText | packages/desktop/src/main/files/clipboard.ts | Reads image buffers and writes text to system clipboard. | tauri-plugin-clipboard-manager (option) or arboard crate | https://v2.tauri.app/plugin/clipboard/ | S | Low | Cross-platform text and image clipboard support. |
| Native Notifications | Notification (Electron / Web API) | packages/desktop/src/renderer/platform/notifications.ts | Background completion alerts; clicking focuses window. | tauri-plugin-notification (option) | https://v2.tauri.app/plugin/notification/ | S | Low | Standard OS notifications. |
| External Browser & Path Opening | shell.openExternal, shell.openPath, shell.showItemInFolder | packages/desktop/src/main/files/external-url.ts | Opens default web browser, reveals files in file manager. | tauri-plugin-opener (option) or open crate | https://v2.tauri.app/plugin/opener/ | S | Low | Standard cross-platform opener. |
| Auto-Updater | electron-updater, app-update.yml | packages/desktop/src/main/lifecycle/updater.ts | Fetches updates from opencode.ai feeds, verifies signatures. | tauri-plugin-updater (option) | https://v2.tauri.app/plugin/updater/ | L | High | Requires translating Tauri JSON update manifest format or adapter endpoint. |
| Crash Reporter & Logging | crashReporter.start, electron-log | packages/desktop/src/main/native/logging.ts | Minidumps, rotated text logs, Sentry crash capture. | sentry-rust crate (option) + tracing | https://docs.rs/sentry/latest/sentry/ | M | Med | Standard Rust tracing and Sentry integration. |
| Microphone Permissions | systemPreferences.askForMediaAccess('microphone') | packages/desktop/src/main/ipc-handlers/window.ts | macOS-specific privacy prompt for voice conversations. | objc2 / cocoa framework call on macOS (option) | https://docs.rs/objc2/latest/objc2/ | S | Med | Standard macOS AVCaptureDevice permission API. |
| Background Throttling | webContents.setBackgroundThrottling(bool) | packages/desktop/src/main/ipc-handlers/window.ts | Prevents throttling during voice calls. | Wry / webview configuration (option) | https://docs.rs/wry/latest/wry/ | S | Low | System webviews handle audio threads natively. |
| Context Menus | electron-context-menu, Menu.popup | packages/desktop/src/main/lifecycle/environment.ts | Right-click context menus (Cut, Copy, Paste). | tauri-plugin-context-menu (option) | https://github.com/c2r0b/tauri-plugin-context-menu | S | Low | Straightforward plugin or DOM menu. |
| Spellcheck Configuration | session.setSpellCheckerLanguages | packages/desktop/src/main/native/spellcheck.ts | Native spellchecking on text inputs. | System webview native spellcheck (option) | https://v2.tauri.app/reference/javascript/api/namespacewebview/ | S | Low | Supported out-of-the-box in system webviews. |
| Zoom Level Control | webContents.setZoomFactor | packages/desktop/src/main/windows/defaults.ts | Zoom levels (80% to 150%) and touchpad pinch gestures. | tauri::Webview::set_zoom (option) | https://docs.rs/tauri/latest/tauri/webview/struct.Webview.html#method.set_zoom | S | Low | Direct API exposed in Tauri v2. |

## 2. Chromium vs System Webview Behavioral Risks

1. **Linux WebKitGTK Font & CSS Rendering** (*known*): Subpixel antialiasing and subgrid layout in WebKitGTK differ slightly from Chromium.
2. **Asset Serving Custom Protocols** (*known*): Electron custom scheme (`registerRendererScheme`) maps to Tauri's `tauri://localhost` asset loader.
3. **Touchpad Pinch Gestures** (*inferred*): Supported natively on macOS and Windows; Linux WebKitGTK depends on Wayland/GTK touchpad drivers.
4. **Developer Tools** (*known*): Platform-native devtools (WebKit inspector, Edge WebView2 devtools) replace Chrome DevTools.
5. **IME and Text Layout** (*unverified*): Complex IME text composition in CJK languages should be validated across platforms.

## 3. Packaging and Distribution Matrix

- **Linux**: AppImage, deb, rpm via `cargo-tauri` / `tauri-cli`.
- **macOS**: .app, .dmg, .zip via `cargo-tauri` with Apple codesign and notarytool integration.
- **Windows**: NSIS installer (.exe) via `cargo-tauri`.
