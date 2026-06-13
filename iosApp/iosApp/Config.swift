import Foundation

/// The bike dash's External Accessory protocol string, used only by the bike transport
/// (release builds, or on-device dev testing against the real dash).
///
/// PLACEHOLDER — verify on a connected bike via `EAAccessory.protocolStrings`, and list the same
/// value under `UISupportedExternalAccessoryProtocols` in Info.plist.
let bikeProtocolString = "com.garmin.navilite.data"
