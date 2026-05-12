import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let deviceInfoChannelName = "amana_pos/device_info"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        setupDeviceInfoMethodChannel()

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    private func setupDeviceInfoMethodChannel() {
        guard let registrar = self.registrar(forPlugin: "AmanaPosDeviceInfoChannel") else {
            print("[DeviceInfoChannel] Failed to create Flutter registrar")
            return
        }

        let channel = FlutterMethodChannel(
            name: deviceInfoChannelName,
            binaryMessenger: registrar.messenger()
        )

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getDeviceId":
                result(DeviceUUID.getUUID())

            case "getAppVersion":
                result(AppVersionInfo.getAppVersion())

            case "getBuildNumber":
                result(AppVersionInfo.getBuildNumber())

            case "getDeviceMeta":
                result([
                           "deviceId": DeviceUUID.getUUID(),
                           "appVersion": AppVersionInfo.getAppVersion(),
                           "buildNumber": AppVersionInfo.getBuildNumber(),
                           "platform": "ios"
                       ])

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        print("[DeviceInfoChannel] Registered successfully")
    }
}

struct AppVersionInfo {
    static func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    static func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}

struct DeviceUUID {
    private static let serviceIdentifier = "com.amanapos.device_uuid"
    private static let accountIdentifier = "com.amanapos.device_uuid_key"

    static func getUUID() -> String {
        if let existingUUID = readUUID(), !existingUUID.isEmpty {
            return existingUUID
        }

        let newUUID = UUID().uuidString
        saveUUID(newUUID)
        return newUUID
    }

    private static func readUUID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let uuid = String(data: data, encoding: .utf8),
              !uuid.isEmpty else {
            return nil
        }

        return uuid
    }

    private static func saveUUID(_ uuid: String) {
        guard let data = uuid.data(using: .utf8) else {
            return
        }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountIdentifier
        ]

        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status != errSecSuccess {
            print("[DeviceUUID] Failed to save UUID in Keychain. Status: \(status)")
        }
    }
}