import AppKit

MainActor.assumeIsolated {
    if let commandExitCode = AppDelegate.handleCommandLineArguments() {
        exit(commandExitCode)
    }

    let application = NSApplication.shared
    let applicationDelegate = AppDelegate()
    application.delegate = applicationDelegate
    application.run()
}
