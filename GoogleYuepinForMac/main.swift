import AppKit

MainActor.assumeIsolated {
    if AppDelegate.handleRegistrationArgument() {
        exit(0)
    }

    let application = NSApplication.shared
    let applicationDelegate = AppDelegate()
    application.delegate = applicationDelegate
    application.run()
}
