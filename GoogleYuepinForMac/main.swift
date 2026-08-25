import AppKit

MainActor.assumeIsolated {
    if let registrationExitCode = AppDelegate.handleRegistrationArgument() {
        exit(registrationExitCode)
    }

    let application = NSApplication.shared
    let applicationDelegate = AppDelegate()
    application.delegate = applicationDelegate
    application.run()
}
