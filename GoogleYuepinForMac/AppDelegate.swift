import AppKit
import Carbon
import InputMethodKit
import os.log

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "local.googleyuepinformac.inputmethod",
        category: "input-method"
    )

    static private(set) var candidateService: (any CandidateProviding)?
    private var server: IMKServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            let supportURL = try Self.applicationSupportURL()
            let cache = try CandidateCache(path: supportURL.appendingPathComponent("candidate-cache.sqlite3"))
            Self.candidateService = CachedCandidateService(
                provider: GoogleCandidateProvider(),
                cache: cache
            )
            Task {
                try? await cache.removeExpired()
            }
        } catch {
            Self.logger.error("Candidate cache could not be initialized: \(error.localizedDescription, privacy: .public)")
            Self.candidateService = GoogleCandidateProvider()
        }

        let connectionName = Bundle.main.object(forInfoDictionaryKey: "InputMethodConnectionName") as? String
            ?? "local.googleyuepinformac.inputmethod_Connection"
        let identifier = Bundle.main.bundleIdentifier ?? "local.googleyuepinformac.inputmethod"
        server = IMKServer(name: connectionName, bundleIdentifier: identifier)
        Self.logger.notice("GoogleYuepinForMac input method server started")
    }

    static func handleRegistrationArgument() -> Bool {
        guard CommandLine.arguments.contains("--register") else { return false }
        let result = TISRegisterInputSource(Bundle.main.bundleURL as CFURL)
        if result != noErr {
            fputs("Failed to register input source (OSStatus \(result)).\n", stderr)
            return true
        }
        print("Registered GoogleYuepinForMac. Add it in System Settings > Keyboard > Text Input.")
        return true
    }

    private static func applicationSupportURL() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = root.appendingPathComponent("GoogleYuepinForMac", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
