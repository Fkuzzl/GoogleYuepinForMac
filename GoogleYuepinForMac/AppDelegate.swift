import AppKit
import Carbon
import InputMethodKit
import os.log

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let bundleIdentifier = "local.googleyuepinformac.inputmethod"
    private static let inputModeIdentifier = "local.googleyuepinformac.inputmethod.GoogleYuepinIM"

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

    static func handleCommandLineArguments() -> Int32? {
        if CommandLine.arguments.contains("--register") {
            return registerInputSource()
        }
        if CommandLine.arguments.contains("--enable") {
            return enableInputSource()
        }
        return nil
    }

    private static func registerInputSource() -> Int32 {
        let result = TISRegisterInputSource(Bundle.main.bundleURL as CFURL)
        if result != noErr {
            fputs("Failed to register input source (OSStatus \(result)).\n", stderr)
            return 1
        }
        print("Registered GoogleYuepinForMac with Text Input Source Services.")
        return 0
    }

    private static func enableInputSource() -> Int32 {
        let enabledCount = enableRegisteredInputSources()
        guard enabledCount > 0 else {
            fputs("macOS has not discovered the registered input source yet.\n", stderr)
            return 1
        }

        print("Enabled GoogleYuepinForMac (\(enabledCount) input source records).")
        return 0
    }

    private static func enableRegisteredInputSources() -> Int {
        let expectedIdentifiers: Set<String> = [bundleIdentifier, inputModeIdentifier]
        guard let inputSources = TISCreateInputSourceList(nil, true).takeRetainedValue() as? [TISInputSource] else {
            return 0
        }

        var enabledCount = 0
        for inputSource in inputSources {
            guard let property = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else {
                continue
            }
            let identifier = Unmanaged<CFString>.fromOpaque(property).takeUnretainedValue() as String
            guard expectedIdentifiers.contains(identifier) else { continue }

            let result = TISEnableInputSource(inputSource)
            if result == noErr {
                enabledCount += 1
            } else {
                fputs("Failed to enable \(identifier) (OSStatus \(result)).\n", stderr)
            }
        }
        return enabledCount
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
