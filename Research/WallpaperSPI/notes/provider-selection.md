# Provider-selection observations

## Static host evidence

The Wallspace 1.6 host was opened read-only in IDA under the explicit session
`movo-wallspace-host`. No live process was injected, patched, or hooked.

### Observed strings and types

- `WallpaperExtensionDeploymentService`
- `WallpaperIndexPlistService`
- `LockScreenWallpaperApplyService`
- `WallpaperAgentRefresh`
- extension bundle ID `wallspace.app.wallpaper-extension`
- extension-container `Data/Documents` path
- wallpaper-store `Index.plist` path
- diagnostics describing an extension `Idle` entry write
- diagnostics describing removal from `Idle` and `Linked`
- diagnostics describing extension activation, first-acquire restart, provider
  reapply, and rollback/error branches

### Inferred sequence

The smallest sequence consistent with those observations is:

1. deploy managed video/metadata into the extension container;
2. prepare or update an extension choice/slot;
3. modify the selected provider under the relevant `Idle`/`Linked` store node;
4. notify or restart the minimum wallpaper runtime needed for acquisition;
5. verify the extension started and acquired the selection.

This sequence is deliberately not pseudocode and is not safe to implement from
static strings. It omits unknown transaction, locking, backup, and notification
details.

## Unresolved runtime choice route

The private framework exports a choice-request handler and selected-choice
observer. This is positive evidence for a runtime-mediated choice mechanism,
but not proof that a third-party host can select the provider or destination.

Gate 1 therefore requires two controlled reproductions of whichever mechanism
is selected. Until then:

- runtime choice remains preferred but unproven;
- direct store mutation remains a disabled fallback;
- no experiment may run in the current user's account.
