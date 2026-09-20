import Carbon.HIToolbox
import Foundation
import os

/// One system-wide shortcut: a virtual key code, its Carbon modifier mask, and
/// the id `GlobalHotKeys` reports back when it fires.
struct HotKeyBinding: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let id: UInt32

    /// `Control+Option` rather than `Option` alone: on a German layout ⌥ plus a
    /// digit or letter types a character (⌥5 is `[`, ⌥7 is `|`, ⌥L is `@`), and
    /// a registered hot key swallows the keystroke before any text field sees
    /// it. ⌃⌥ produces no character on any layout.
    static let modifiers = UInt32(controlKey | optionKey)

    /// `kVK_ANSI_1`…`kVK_ANSI_9`, which are not in numeric order.
    static let sceneKeyCodes: [UInt32] = [18, 19, 20, 21, 23, 22, 26, 28, 25]
    /// `kVK_ANSI_P`, registered under an id past the end of the scene ids.
    static let pauseKeyCode: UInt32 = 35
    static let pauseID = UInt32(100)

    static let defaults: [HotKeyBinding] =
        sceneKeyCodes.enumerated().map {
            HotKeyBinding(keyCode: $1, modifiers: modifiers, id: UInt32($0))
        } + [HotKeyBinding(keyCode: pauseKeyCode, modifiers: modifiers, id: pauseID)]
}

/// System-wide ⌃⌥1…⌃⌥9 for switching scenes and ⌃⌥P for pausing.
///
/// The menu-bar shortcuts only fire while OpenLens is frontmost, which is never
/// the case during a call — the whole point is to re-frame yourself without
/// leaving Zoom. `RegisterEventHotKey` is used rather than an `NSEvent` global
/// monitor because it needs no Accessibility permission and works from inside
/// the sandbox.
@MainActor
final class GlobalHotKeys {
    /// Called with a zero-based scene index.
    var onSelect: ((Int) -> Void)?
    /// Called for ⌃⌥P.
    var onTogglePause: (() -> Void)?

    private var refs: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?
    private static let signature = OSType(0x4F4C_4E53)  // 'OLNS'

    private let log = Logger(subsystem: OpenLensID.appBundleID, category: "hotkeys")

    private static weak var active: GlobalHotKeys?

    func register() {
        guard handler == nil else { return }
        Self.active = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard result == noErr, hotKeyID.signature == GlobalHotKeys.signature else {
                    return OSStatus(eventNotHandledErr)
                }
                let id = hotKeyID.id
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        guard let active = GlobalHotKeys.active else { return }
                        if id == HotKeyBinding.pauseID {
                            active.onTogglePause?()
                        } else {
                            active.onSelect?(Int(id))
                        }
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &handler
        )
        guard status == noErr else {
            log.error("Could not install the hot key handler: OSStatus \(status)")
            return
        }

        for binding in HotKeyBinding.defaults {
            var ref: EventHotKeyRef?
            let registered = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                EventHotKeyID(signature: Self.signature, id: binding.id),
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if registered == noErr, let ref {
                refs.append(ref)
            } else {
                log.error(
                    "Could not register hot key \(binding.id) (key code \(binding.keyCode)): OSStatus \(registered)"
                )
            }
        }
    }

    func unregister() {
        for ref in refs { UnregisterEventHotKey(ref) }
        refs.removeAll()
        if let handler {
            RemoveEventHandler(handler)
            self.handler = nil
        }
        if Self.active === self { Self.active = nil }
    }

    deinit {
        for ref in refs { UnregisterEventHotKey(ref) }
        if let handler { RemoveEventHandler(handler) }
    }
}
