# Audit: IPC and Preload Inventory (J-002)

## Overview and Architecture

In OpenCode Desktop (`upstream/packages/desktop`), communication between the frontend GUI (renderer) and the desktop shell (main process) is structured into two distinct tiers:

1. **Preload / Electron Primitive Channels**:
   - Exposed through Electron's `contextBridge` (`window.electron`) and `ipcRenderer` in `src/preload/index.ts`.
   - Used for initial window bootstrapping, synchronous file path resolution (`webUtils.getPathForFile`), and handing off a high-performance `MessagePort` to the renderer.
2. **MessagePort RPC Layer**:
   - Operates entirely over a `MessagePort` (`IpcTransportPort = "desktop-rpc-port"`) transferred from main to renderer on window load.
   - Built using Effect's RPC wire format (`RpcClient` / `RpcServer`), bypassing Electron's JSON serialization and preserving typed structured cloning (including `Uint8Array` binary payloads).
   - Defined across RPC schemas in `src/shared/ipc-rpc/*.ts`, composed in `src/shared/ipc-rpc.ts`, implemented in `src/main/ipc-handlers/*.ts`, and consumed by `src/renderer/api.ts` and `src/renderer/plugins.ts`.
   - Bidirectional real-time events are streamed from main to renderer over a single streaming RPC: `DesktopEvents`.

---

## 1. Preload Interface (`window.electron`)

Defined in `upstream/packages/desktop/src/preload/index.ts:22-28`:

| Property / Method | Type / Signature | Description |
|---|---|---|
| `windowID` | `string` | Unique UUID for the window instance (`bootstrap.id`). |
| `bootstrap` | `WindowBootstrap` | Parsed command-line arguments passed to the window process. |
| `storageSnapshot` | `Promise<StorageSnapshot>` | Preloaded SQLite/storage snapshot resolved via `desktop-window-snapshot` before mount. |
| `plugins` | `Promise<readonly EnableState[] \| undefined>` | Preloaded plugin enablement state. |
| `getPathForFile(file: File)` | `(file: File) => string` | Native file path resolution using Electron `webUtils.getPathForFile(file)`. |

---

## 2. Electron IPC Channels

| Channel Name | Direction | Pattern | Payload | Response | Description |
|---|---|---|---|---|---|
| `desktop-window-snapshot` | Renderer -> Main | `ipcRenderer.invoke` / `ipcMain.handle` | `names: string[]` | `WindowSnapshot` | Fetches initial key-value namespaces before page render. |
| `desktop-rpc-port` | Main -> Renderer | `webContents.postMessage` / `window.postMessage` | `MessagePort` transfer | `void` | Hands off the dedicated RPC MessagePort. |
| `opencode:drag-cancel` | Main -> Renderer | `webContents.send` / `window.dispatchEvent` | `void` | `void` | Signals drag cancel when Escape key is pressed. |

---

## 3. Complete MessagePort RPC Inventory (64 Methods)

| Channel / Tag | Direction | Payload Shape | Response Shape | Error Behavior | Caller Path & Symbol | Handler Path & Symbol | Side Effects | Platform |
|---|---|---|---|---|---|---|---|---|
| `AppAwaitInitialization` | renderer-to-main | `null` | `ServerReadyData: { url: string; password?: string }` | Rejects if service startup fails or times out | `api.awaitInitialization`<br>(upstream/packages/desktop/src/renderer/api.ts:24) | `appHandlers.AppAwaitInitialization`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:33) | Awaits CLI background service startup | All |
| `AppReconnectService` | renderer-to-main | `null` | `ServerReadyData: { url: string; password?: string }` | Rejects if service reconnection fails | `api.reconnectService`<br>(upstream/packages/desktop/src/renderer/api.ts:25) | `appHandlers.AppReconnectService`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:34) | Restarts/reconnects background CLI daemon | All |
| `AppConsumeInitialDeepLinks` | renderer-to-main | `null` | `string[]` | Returns empty array on failure | `api.consumeInitialDeepLinks`<br>(upstream/packages/desktop/src/renderer/api.ts:26) | `appHandlers.AppConsumeInitialDeepLinks`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:35) | Drains buffered startup deep link URLs | All |
| `AppIsFirstLaunchOnboardingPending` | renderer-to-main | `null` | `boolean` | Returns boolean flag | `api.isFirstLaunchOnboardingPending`<br>(upstream/packages/desktop/src/renderer/api.ts:27) | `appHandlers.AppIsFirstLaunchOnboardingPending`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:36) | Checks onboarding flag in persistent store | All |
| `AppFinishFirstLaunchOnboarding` | renderer-to-main | `{ createDefaultProject: boolean }` | `string | null` | Defect / die on filesystem error | `api.finishFirstLaunchOnboarding`<br>(upstream/packages/desktop/src/renderer/api.ts:28) | `appHandlers.AppFinishFirstLaunchOnboarding`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:37) | Creates initial project directory and marks onboarding complete | All |
| `AppCheckAppExists` | renderer-to-main | `{ appName: string }` | `boolean` | Returns false on error | `api.checkAppExists`<br>(upstream/packages/desktop/src/renderer/api.ts:30) | `appHandlers.AppCheckAppExists`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:39) | Checks if external editor/terminal app exists on host | Conditional |
| `AppResolveAppPath` | renderer-to-main | `{ appName: string }` | `string | null` | Returns null if not found | `api.resolveAppPath`<br>(upstream/packages/desktop/src/renderer/api.ts:31) | `appHandlers.AppResolveAppPath`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:40) | Locates host executable binary path | Conditional |
| `AppSetBackgroundColor` | renderer-to-main | `{ color: string }` | `void` | No-op on invalid window | `api.setBackgroundColor`<br>(upstream/packages/desktop/src/renderer/api.ts:75) | `appHandlers.AppSetBackgroundColor`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:41) | Sets native window background color and saves to store | All |
| `AppGetSpellcheckEnabled` | renderer-to-main | `null` | `boolean` | Returns boolean | `api.getSpellcheckEnabled`<br>(upstream/packages/desktop/src/renderer/api.ts:78) | `appHandlers.AppGetSpellcheckEnabled`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:42) | Reads spellcheck preference from store | All |
| `AppSetSpellcheckEnabled` | renderer-to-main | `{ enabled: boolean }` | `void` | Saves preference to store | `api.setSpellcheckEnabled`<br>(upstream/packages/desktop/src/renderer/api.ts:79) | `appHandlers.AppSetSpellcheckEnabled`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:43) | Configures webContents.session spellcheck and persists setting | All |
| `AppExportDebugLogs` | renderer-to-main | `null` | `string` | Rejects if log gathering fails | `api.exportDebugLogs`<br>(upstream/packages/desktop/src/renderer/api.ts:76) | `appHandlers.AppExportDebugLogs`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:44) | Collects system/app log files into text string | All |
| `AppSetForceFocus` | renderer-to-main | `{ enabled: boolean }` | `void` | Dies on failure | `api.setForceFocus`<br>(upstream/packages/desktop/src/renderer/api.ts:77) | `appHandlers.AppSetForceFocus`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:45) | Enables/disables developer focus debugging hook | All |
| `AppRecordFatalRendererError` | renderer-to-main | `{ error: FatalRendererError }` | `void` | Logs error in main process log | `api.recordFatalRendererError`<br>(upstream/packages/desktop/src/renderer/api.ts:80) | `appHandlers.AppRecordFatalRendererError`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:46) | Writes fatal renderer crash information to log file | All |
| `AppSetNativeTranslations` | renderer-to-main | `{ value: DesktopNativeBundle }` | `void` | Throws on invalid sender or invalid bundle | `api.setNativeTranslations`<br>(upstream/packages/desktop/src/renderer/api.ts:81) | `appHandlers.AppSetNativeTranslations`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:48) | Updates native application menu strings and rebuilds menu | All |
| `AppRelaunch` | renderer-to-main | `null` | `void` | Ignored on failure | `api.relaunch`<br>(upstream/packages/desktop/src/renderer/api.ts:63) | `appHandlers.AppRelaunch`<br>(upstream/packages/desktop/src/main/ipc-handlers/app.ts:74) | Relaunches the desktop application and exits current process | All |
| `FilesOpenDirectoryPicker` | renderer-to-main | `{ options?: DirectoryPickerOptions }` | `string | string[] | null` | Returns null if cancelled or error | `api.openDirectoryPicker`<br>(upstream/packages/desktop/src/renderer/api.ts:47) | `fileHandlers.FilesOpenDirectoryPicker`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:13) | Shows OS native folder picker dialog | All |
| `FilesOpenFilePicker` | renderer-to-main | `{ options?: FilePickerOptions }` | `PickedFiles | null` | Returns null if cancelled | `api.openFilePicker`<br>(upstream/packages/desktop/src/renderer/api.ts:48) | `fileHandlers.FilesOpenFilePicker`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:14) | Shows OS native file picker dialog and issues security token | All |
| `FilesReadPickedFile` | renderer-to-main | `{ token: string; path: string }` | `Uint8Array (converted to ArrayBuffer)` | Rejects if token unauthorized or file unreadable | `api.readPickedFile`<br>(upstream/packages/desktop/src/renderer/api.ts:49) | `fileHandlers.FilesReadPickedFile`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:21) | Reads authorized file contents from host disk | All |
| `FilesReleasePickedFiles` | renderer-to-main | `{ token: string }` | `void` | Releases token silently | `api.releasePickedFiles`<br>(upstream/packages/desktop/src/renderer/api.ts:50) | `fileHandlers.FilesReleasePickedFiles`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:25) | Invalidates file access authorization token | All |
| `FilesSaveFile` | renderer-to-main | `{ options: SaveFilePickerOptions; content: string }` | `boolean` | Returns false on cancellation or write failure | `api.saveFile`<br>(upstream/packages/desktop/src/renderer/api.ts:52) | `fileHandlers.FilesSaveFile`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:27) | Shows OS save file dialog and writes file to host disk | All |
| `FilesOpenExternal` | renderer-to-main | `{ url: string }` | `void` | Ignored on failure | `api.openExternal`<br>(upstream/packages/desktop/src/renderer/api.ts:53) | `fileHandlers.FilesOpenExternal`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:28) | Opens URL in user's default external browser/app | All |
| `FilesOpenBrowser` | renderer-to-main | `{ url: string }` | `boolean` | Returns false if URL is not http/https | `api.openBrowser`<br>(upstream/packages/desktop/src/renderer/api.ts:54) | `fileHandlers.FilesOpenBrowser`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:29) | Validates http(s) URL and opens default web browser | All |
| `FilesOpenLocalFile` | renderer-to-main | `{ url: string }` | `void` | Ignored on invalid path | `api.openLocalFile`<br>(upstream/packages/desktop/src/renderer/api.ts:55) | `fileHandlers.FilesOpenLocalFile`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:30) | Opens local file using desktop default application | All |
| `FilesOpenPath` | renderer-to-main | `{ path: string; application?: string }` | `string | null` | Returns error message string on failure, or null on success | `api.openPath`<br>(upstream/packages/desktop/src/renderer/api.ts:56) | `fileHandlers.FilesOpenPath`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:31) | Launches external editor/application with target path | Conditional |
| `FilesRevealPath` | renderer-to-main | `{ path: string }` | `boolean` | Returns false if file not found | `api.revealPath`<br>(upstream/packages/desktop/src/renderer/api.ts:57) | `fileHandlers.FilesRevealPath`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:36) | Highlights file in OS file manager (Finder / Explorer / Nautilus) | All |
| `FilesReadClipboardImage` | renderer-to-main | `null` | `ClipboardImage | null` | Returns null if clipboard has no image | `api.readClipboardImage`<br>(upstream/packages/desktop/src/renderer/api.ts:58) | `fileHandlers.FilesReadClipboardImage`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:37) | Reads native OS clipboard image buffer | All |
| `FilesWriteClipboardText` | renderer-to-main | `{ text: string }` | `void` | Writes text to clipboard | `api.writeClipboardText`<br>(upstream/packages/desktop/src/renderer/api.ts:62) | `fileHandlers.FilesWriteClipboardText`<br>(upstream/packages/desktop/src/main/ipc-handlers/files.ts:38) | Sets native OS clipboard text | All |
| `MenuRunAction` | renderer-to-main | `{ action: DesktopMenuAction }` | `void` | Executes menu action in main process | `api.runDesktopMenuAction`<br>(upstream/packages/desktop/src/renderer/api.ts:74) | `menuHandlers.MenuRunAction`<br>(upstream/packages/desktop/src/main/ipc-handlers/menu.ts:16) | Triggers native window/menu commands (new window, zoom, reload, etc.) | All |
| `StorageItems` | renderer-to-main | `{ name: string }` | `{ items: Record<string, string>; revision: number }` | Returns empty items object on missing store | `api.storeItems`<br>(upstream/packages/desktop/src/renderer/api.ts:35) | `storageHandlers.StorageItems`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:16) | Reads key-value snapshot from SQLite persistence database | All |
| `StorageUpdate` | renderer-to-main | `{ name: string; insert: Record<string, string>; remove: string[] }` | `number (revision)` | Updates database and broadcasts StorageChanged event to other windows | `api.storeUpdate`<br>(upstream/packages/desktop/src/renderer/api.ts:40) | `storageHandlers.StorageUpdate`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:17) | Writes key-value updates to SQLite database; emits StorageChanged | All |
| `StorageClear` | renderer-to-main | `{ name: string }` | `void` | Clears namespace in database | `api.storeClear`<br>(upstream/packages/desktop/src/renderer/api.ts:41) | `storageHandlers.StorageClear`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:30) | Clears key-value entries in SQLite database | All |
| `DraftsGet` | renderer-to-main | `{ key: string }` | `string | null` | Returns null if draft key absent | `api.draftGet`<br>(upstream/packages/desktop/src/renderer/api.ts:42) | `storageHandlers.DraftsGet`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:31) | Reads draft text entry from SQLite | All |
| `DraftsSet` | renderer-to-main | `{ key: string; value: string; strict: boolean }` | `string[]` | Persists draft; returns evicted keys | `api.draftSet`<br>(upstream/packages/desktop/src/renderer/api.ts:43) | `storageHandlers.DraftsSet`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:32) | Writes draft text to SQLite storage | All |
| `DraftsDelete` | renderer-to-main | `{ key: string }` | `void` | Deletes draft key | `api.draftDelete`<br>(upstream/packages/desktop/src/renderer/api.ts:44) | `storageHandlers.DraftsDelete`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:33) | Removes draft entry from SQLite | All |
| `DraftsPutBlob` | renderer-to-main | `{ data: Uint8Array }` | `string (blob ID)` | Stores binary draft blob and returns sha/id | `api.draftBlobPut`<br>(upstream/packages/desktop/src/renderer/api.ts:45) | `storageHandlers.DraftsPutBlob`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:34) | Writes binary attachment blob to SQLite | All |
| `DraftsGetBlob` | renderer-to-main | `{ id: string }` | `Uint8Array | null` | Returns null if blob not found | `api.draftBlobGet`<br>(upstream/packages/desktop/src/renderer/api.ts:46) | `storageHandlers.DraftsGetBlob`<br>(upstream/packages/desktop/src/main/ipc-handlers/storage.ts:35) | Reads binary attachment blob from SQLite | All |
| `WindowThemeReady` | renderer-to-main | `null` | `void` | Marks early window theme initialization complete | `api.themeReady`<br>(upstream/packages/desktop/src/renderer/api.ts:38) | `windowHandlers.WindowThemeReady`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:34) | Transitions window opacity / frame from bootstrap state | All |
| `WindowRequestMicrophone` | renderer-to-main | `null` | `boolean` | Returns permission grant boolean | `api.requestMicrophone`<br>(upstream/packages/desktop/src/renderer/api.ts:60) | `windowHandlers.WindowRequestMicrophone`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:24) | Prompts OS microphone permissions on macOS (systemPreferences.askForMediaAccess) | Conditional |
| `WindowSetVoiceCallActive` | renderer-to-main | `{ active: boolean }` | `void` | Controls webContents background throttling | `api.setVoiceCallActive`<br>(upstream/packages/desktop/src/renderer/api.ts:61) | `windowHandlers.WindowSetVoiceCallActive`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:28) | Disables Chromium background throttling during active calls | All |
| `WindowGetFocused` | renderer-to-main | `null` | `boolean` | Returns false if window destroyed | `api.getWindowFocused`<br>(upstream/packages/desktop/src/renderer/api.ts:59) | `windowHandlers.WindowGetFocused`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:40) | Queries BrowserWindow isFocused state | All |
| `WindowGetFullscreen` | renderer-to-main | `null` | `boolean` | Returns false if window destroyed | `api.getWindowFullscreen`<br>(upstream/packages/desktop/src/renderer/api.ts:62) | `windowHandlers.WindowGetFullscreen`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:42) | Queries BrowserWindow isFullScreen state | All |
| `WindowSetFocus` | renderer-to-main | `null` | `void` | Focuses window | `api.setWindowFocus`<br>(upstream/packages/desktop/src/renderer/api.ts:64) | `windowHandlers.WindowSetFocus`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:44) | Focuses native window and activates application | Conditional |
| `WindowShow` | renderer-to-main | `null` | `void` | Shows window | `api.showWindow`<br>(upstream/packages/desktop/src/renderer/api.ts:65) | `windowHandlers.WindowShow`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:46) | Restores and displays native BrowserWindow | All |
| `WindowGetZoomFactor` | renderer-to-main | `null` | `number` | Returns live zoomFactor | `api.getZoomFactor`<br>(upstream/packages/desktop/src/renderer/api.ts:66) | `windowHandlers.WindowGetZoomFactor`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:47) | Queries webContents zoom factor | All |
| `WindowSetZoomFactor` | renderer-to-main | `{ factor: number }` | `void` | Sets zoom factor | `api.setZoomFactor`<br>(upstream/packages/desktop/src/renderer/api.ts:67) | `windowHandlers.WindowSetZoomFactor`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:48) | Sets webContents zoomFactor and updates titlebar positioning | All |
| `WindowGetZoomLevel` | renderer-to-main | `null` | `DesktopZoomLevel` | Returns saved zoom level setting | `api.getZoomLevel`<br>(upstream/packages/desktop/src/renderer/api.ts:70) | `windowHandlers.WindowGetZoomLevel`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:55) | Reads saved zoom level from store | All |
| `WindowSetZoomLevel` | renderer-to-main | `{ level: DesktopZoomLevel }` | `void` | Saves zoom level setting | `api.setZoomLevel`<br>(upstream/packages/desktop/src/renderer/api.ts:71) | `windowHandlers.WindowSetZoomLevel`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:56) | Persists zoom level and broadcasts WindowZoomChanged | All |
| `WindowGetPinchZoomEnabled` | renderer-to-main | `null` | `boolean` | Returns pinch-zoom enabled setting | `api.getPinchZoomEnabled`<br>(upstream/packages/desktop/src/renderer/api.ts:68) | `windowHandlers.WindowGetPinchZoomEnabled`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:57) | Reads pinch zoom preference from store | All |
| `WindowSetPinchZoomEnabled` | renderer-to-main | `{ enabled: boolean }` | `void` | Saves pinch-zoom preference | `api.setPinchZoomEnabled`<br>(upstream/packages/desktop/src/renderer/api.ts:69) | `windowHandlers.WindowSetPinchZoomEnabled`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:58) | Persists pinch zoom preference and broadcasts WindowPinchZoomChanged | All |
| `WindowSetTitlebar` | renderer-to-main | `{ theme: TitlebarTheme }` | `void` | Updates window titlebar appearance | `api.setTitlebar`<br>(upstream/packages/desktop/src/renderer/api.ts:72) | `windowHandlers.WindowSetTitlebar`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:59) | Configures native window frame / titlebar colors | Conditional |
| `WindowSetTrafficLightsPosition` | renderer-to-main | `{ x: number; y: number }` | `void` | Sets window windowButtonPosition | `api.setTrafficLightsPosition`<br>(upstream/packages/desktop/src/renderer/api.ts:73) | `windowHandlers.WindowSetTrafficLightsPosition`<br>(upstream/packages/desktop/src/main/ipc-handlers/window.ts:64) | Sets macOS traffic light window button inset position | Conditional |
| `PluginCall` | renderer-to-main | `any (PluginCallRequest)` | `any` | Fails with PluginFailure error code | `createPluginBridge().call`<br>(upstream/packages/desktop/src/renderer/plugins.ts:42) | `pluginHandlers.PluginCall`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:30) | Dispatches RPC call to active plugin host | All |
| `PluginSubscribe` | renderer-to-main | `{ ipc: string }` | `void` | Subscribes caller window to plugin events | `createPluginBridge().subscribe`<br>(upstream/packages/desktop/src/renderer/plugins.ts:46) | `pluginHandlers.PluginSubscribe`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:35) | Registers window subscription in plugin host | All |
| `PluginEmbed` | renderer-to-main | `{ id: string; layout?: PluginLayout }` | `void` | Positions embedded native plugin view | `createPluginBridge().embed`<br>(upstream/packages/desktop/src/renderer/plugins.ts:57) | `pluginHandlers.PluginEmbed`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:36) | Mounts/moves WebContentsView / native embed view in window | All |
| `PluginCapture` | renderer-to-main | `{ id: string }` | `Uint8Array | null` | Returns null if capture fails | `createPluginBridge().capture`<br>(upstream/packages/desktop/src/renderer/plugins.ts:58) | `pluginHandlers.PluginCapture`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:37) | Captures image snapshot of embedded plugin view | All |
| `PluginMenubarItem` | renderer-to-main | `{ id: string }` | `void` | Runs plugin menubar action | `createPluginBridge().runMenubarItem`<br>(upstream/packages/desktop/src/renderer/plugins.ts:59) | `pluginHandlers.PluginMenubarItem`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:39) | Triggers plugin action from menubar click | All |
| `PluginMenubarItems` | renderer-to-main | `null` | `PluginMenubarItem[]` | Returns empty array on failure | `createPluginBridge() menubar query`<br>(upstream/packages/desktop/src/renderer/plugins.ts:32) | `pluginHandlers.PluginMenubarItems`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:40) | Lists plugin-contributed menubar items | All |
| `PluginConfigure` | renderer-to-main | `{ servers: PluginEndpoint[] }` | `void` | Configures server endpoints | `createPluginBridge().configure`<br>(upstream/packages/desktop/src/renderer/plugins.ts:60) | `pluginHandlers.PluginConfigure`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:41) | Updates configured server endpoints in plugin host | All |
| `PluginGuis` | renderer-to-main | `null` | `PluginGuis: { plugins: PluginGui[]; reserved: string[] }` | Rejects if plugin host unavailable | `createPluginBridge().pluginGuis`<br>(upstream/packages/desktop/src/renderer/plugins.ts:61) | `pluginHandlers.PluginGuis`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:42) | Retrieves loaded plugin GUI configurations | All |
| `PluginList` | renderer-to-main | `null` | `PluginInstalled[]` | Rejects on host failure | `createPluginBridge().manager.list`<br>(upstream/packages/desktop/src/renderer/plugins.ts:64) | `pluginHandlers.PluginList`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:43) | Lists installed plugins | All |
| `PluginEnable` | renderer-to-main | `{ id: string }` | `void` | Fails with PluginFailure | `createPluginBridge().manager.enable`<br>(upstream/packages/desktop/src/renderer/plugins.ts:65) | `pluginHandlers.PluginEnable`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:44) | Enables plugin and starts instance | All |
| `PluginDisable` | renderer-to-main | `{ id: string }` | `void` | Fails with PluginFailure | `createPluginBridge().manager.disable`<br>(upstream/packages/desktop/src/renderer/plugins.ts:66) | `pluginHandlers.PluginDisable`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:45) | Disables plugin and shuts down instance | All |
| `PluginReload` | renderer-to-main | `{ id: string }` | `void` | Fails with PluginFailure | `createPluginBridge().manager.reload`<br>(upstream/packages/desktop/src/renderer/plugins.ts:67) | `pluginHandlers.PluginReload`<br>(upstream/packages/desktop/src/main/ipc-handlers/plugins.ts:46) | Reloads plugin instance | All |
| `DesktopEvents` | main-to-renderer | `null` | `Stream of DesktopEvent (13 event tags)` | Reconnects on stream interruption | `ipc-client request('DesktopEvents')`<br>(upstream/packages/desktop/src/renderer/ipc-client.ts:58) | `eventHandlers.DesktopEvents`<br>(upstream/packages/desktop/src/main/ipc-handlers/events.ts:10) | Pushes real-time application and window events to renderer | All |

---

## 4. Desktop Events (Streamed via `DesktopEvents`)

All main-to-renderer push notifications and asynchronous updates flow through the single stream RPC `DesktopEvents` (`upstream/packages/desktop/src/shared/ipc-rpc/events.ts`). The stream yields tagged union instances of `DesktopEvent`:

| Event Tag (`_tag`) | Payload Properties | Trigger / Source | Renderer Listener / Effect |
|---|---|---|---|
| `DeepLinksOpened` | `urls: string[]` | OS protocol handler (`opencode://`) activation | Dispatches `onDeepLink` callbacks in `api.ts` |
| `MenuCommandTriggered` | `id: string` | Native application menu click | Dispatches `onMenuCommand` in `api.ts` |
| `WindowFullscreenChanged` | `fullscreen: boolean` | Window enters/exits fullscreen | Updates UI fullscreen state in `api.ts` |
| `WindowFocusChanged` | `focused: boolean` | Window or embed gains/loses focus | Dispatches plugin focus event in `plugins.ts` |
| `WindowPinchZoomChanged` | `enabled: boolean` | Touchpad pinch gesture setting changed | Updates zoom listener in `api.ts` |
| `WindowZoomChanged` | `factor: number, level: string` | Window zoom level adjusted | Updates zoom UI state in `api.ts` |
| `StorageChanged` | `name: string, insert: Record<string, string>, remove: string[], revision: number` | Another window wrote to SQLite storage | Synchronizes multi-window cache in `api.ts` |
| `PluginState` | `ipc: string, state: any` | Main plugin state changed | Dispatches plugin bridge state message |
| `PluginEvent` | `ipc: string, name: string, data: any` | Main plugin emitted event | Dispatches plugin bridge event message |
| `PluginAvailable` | `ipc: string, available: boolean` | Plugin service availability changed | Dispatches plugin availability message |
| `PluginsChanged` | `list: PluginInstalled[]` | Plugin installed or removed | Updates plugin manager list |
| `PluginGuisChanged` | `plugins: PluginGui[], reserved: string[]` | Server registered new plugin GUIs | Re-renders plugin navigation |
| `PluginMenubarItemsChanged` | `items: PluginMenubarItem[]` | Plugin updated menubar contributions | Updates menubar button contributions |

---

## 5. Non-IPC Communication Channels

Beyond Electron IPC and the MessagePort RPC, the renderer and shell interact through the following mechanisms:

1. **Custom Protocol (`app://` or custom renderer scheme)**:
   - Registered in `src/main/windows/scheme.ts` and `protocol.ts` (`registerRendererScheme`, `registerRendererProtocol`).
   - Serves packaged web assets from `out/renderer` directly to Chromium.
2. **CLI Daemon HTTP/SSE API**:
   - The renderer talks directly to the local background server over HTTP/WebSocket (`@opencode/client/service`), using the base URL and credentials provided by `AppAwaitInitialization` (`{ url, password }`).
3. **Command-Line Bootstrap Arguments**:
   - Passed to Chromium via `additionalArguments` in `BrowserWindow` webPreferences (`windowArguments(id)` in `src/main/windows/bootstrap.ts`).
   - Read in preload via `process.argv` and parsed by `windowBootstrapFromArguments`.

---

## 6. Verification and Cross-Check Analysis

- **RPC Definitions in `src/shared/ipc-rpc/`**: 64 (15 App, 12 Files, 1 Menu, 12 Plugins, 8 Storage, 15 Window, 1 Events stream).
- **RPC Handlers in `src/main/ipc-handlers/`**: 64 matching implementations.
- **Electron IPC Primitives**: 3 channels (`desktop-window-snapshot`, `desktop-rpc-port`, `opencode:drag-cancel`).
- **Total Tracked Channels**: 67 channels.
- **Orphans**: Zero orphan channels detected. Every preload export has a caller in `src/renderer`, and every RPC has a matching handler in `src/main`.
- **Dynamic Channels**: None. All channel names are statically declared string literals, ensuring complete type safety and static analyzability for the Rust migration.
- **Platform Conditionals**: Explicit `process.platform` branches exist for macOS microphone permissions (`WindowRequestMicrophone`), traffic lights (`WindowSetTrafficLightsPosition`), window focus stealing (`WindowSetFocus`), external application launching (`FilesOpenPath`, `AppCheckAppExists`), and macOS titlebar appearance.

---

## 7. Migration Implications for Rust Shell

1. **Tauri / Wry Compatibility**:
   - A Rust shell (such as Tauri v2) does not strictly need to implement Electron's `ipcRenderer`/`ipcMain`. Instead, it can implement `window.electron` via preload/init script and instantiate a standard `MessageChannel` (or WebSocket / IPC bridge) that speaks the exact 64-method MessagePort RPC wire format.
2. **Preserving Renderer Without Code Changes**:
   - Because `src/renderer/ipc-client.ts` already speaks plain JSON-RPC over structured messages on a `MessagePort`, the Rust shell can provide the listening port directly on window creation. The entire SolidJS UI will run without modification.
