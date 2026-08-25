import AppKit
import InputMethodKit

@MainActor
@objc(GoogleYuepinInputController)
final class GoogleYuepinInputController: IMKInputController {
    private typealias InputClient = IMKTextInput & NSObjectProtocol

    private let candidateWindow: IMKCandidates
    private var engine = CompositionEngine()
    private var lookupTask: Task<Void, Never>?
    private weak var activeClient: InputClient?

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        candidateWindow = IMKCandidates(
            server: server,
            panelType: kIMKSingleRowSteppingCandidatePanel
        )
        super.init(server: server, delegate: delegate, client: inputClient)
        activeClient = inputClient as? InputClient
        candidateWindow.setDismissesAutomatically(false)
        candidateWindow.setSelectionKeys([18, 19, 20, 21, 23, 22].map(NSNumber.init(value:)))
    }

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue)
    }

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        activeClient = sender as? InputClient ?? client() as? InputClient
        activeClient?.overrideKeyboard(withKeyboardNamed: "com.apple.keylayout.ABC")
    }

    override func deactivateServer(_ sender: Any!) {
        lookupTask?.cancel()
        if engine.isComposing {
            apply(engine.commitRaw(), client: sender as? InputClient)
        }
        candidateWindow.hide()
        activeClient = nil
        super.deactivateServer(sender)
    }

    override func commitComposition(_ sender: Any!) {
        lookupTask?.cancel()
        apply(engine.commitRaw(), client: sender as? InputClient)
        candidateWindow.hide()
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown else { return false }
        let client = sender as? InputClient ?? activeClient
        activeClient = client

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) {
            if engine.isComposing {
                apply(engine.commitRaw(), client: client)
            }
            return false
        }

        switch event.keyCode {
        case 53:
            guard engine.isComposing else { return false }
            apply(engine.cancel(), client: client)
            return true
        case 51:
            guard engine.isComposing else { return false }
            refresh(client: client, effect: engine.backspace())
            return true
        case 36, 76:
            guard engine.isComposing else { return false }
            apply(engine.commitRaw(), client: client)
            return true
        case 49:
            guard engine.isComposing else { return false }
            if engine.selectedCandidate != nil {
                refresh(client: client, effect: engine.selectCandidate())
            } else {
                requestCandidates()
            }
            return true
        case 123:
            guard !engine.candidates.isEmpty else { return engine.isComposing }
            engine.moveSelection(by: -1)
            refreshCandidateWindow(client: client)
            return true
        case 124:
            guard !engine.candidates.isEmpty else { return engine.isComposing }
            engine.moveSelection(by: 1)
            refreshCandidateWindow(client: client)
            return true
        case 125:
            guard !engine.candidates.isEmpty else { return engine.isComposing }
            engine.movePage(by: 1)
            refreshCandidateWindow(client: client)
            return true
        case 126:
            guard !engine.candidates.isEmpty else { return engine.isComposing }
            engine.movePage(by: -1)
            refreshCandidateWindow(client: client)
            return true
        default:
            break
        }

        let text = event.charactersIgnoringModifiers ?? ""
        if text.count == 1, let character = text.first, character.isASCII, character.isLetter {
            refresh(client: client, effect: engine.append(letter: character))
            return true
        }

        if text.count == 1, let digit = text.first?.wholeNumberValue,
           (1...6).contains(digit), !engine.candidates.isEmpty {
            refresh(client: client, effect: engine.selectCandidate(onPage: digit - 1))
            return true
        }

        if let punctuation = ChinesePunctuation.replacement(for: event.characters ?? text) {
            let effect = engine.commitRaw()
            let prefix: String
            if case let .commit(value) = effect {
                prefix = value
            } else {
                prefix = ""
            }
            insert(prefix + punctuation, client: client)
            candidateWindow.hide()
            return true
        }

        if engine.isComposing {
            apply(engine.commitRaw(), client: client)
        }
        return false
    }

    override func candidates(_ sender: Any!) -> [Any]! {
        engine.currentPage.map { NSAttributedString(string: $0.text) }
    }

    override func candidateSelected(_ candidateString: NSAttributedString!) {
        guard let candidateString,
              let pageIndex = engine.currentPage.firstIndex(where: { $0.text == candidateString.string }) else {
            return
        }
        refresh(client: activeClient, effect: engine.selectCandidate(onPage: pageIndex))
    }

    override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        guard let candidateString,
              let pageIndex = engine.currentPage.firstIndex(where: { $0.text == candidateString.string }) else {
            return
        }
        let target = engine.pageNumber * CompositionEngine.pageSize + pageIndex
        engine.moveSelection(by: target - engine.selectedIndex)
        mark(engine.displayText, client: activeClient)
    }

    private func refresh(client: InputClient?, effect: CompositionEffect) {
        switch effect {
        case .none:
            mark(engine.displayText, client: client)
        case .needsCandidates:
            mark(engine.displayText, client: client)
            candidateWindow.hide()
            requestCandidates()
        case .commit, .cancel:
            apply(effect, client: client)
        }
    }

    private func requestCandidates() {
        lookupTask?.cancel()
        guard !engine.rawInput.isEmpty,
              let service = AppDelegate.candidateService else { return }
        let query = engine.lookupQuery

        lookupTask = Task { [weak self] in
            do {
                let candidates = try await service.candidates(for: query, limit: 24)
                guard !Task.isCancelled, let self else { return }
                engine.apply(candidates: candidates, for: query)
                refreshCandidateWindow(client: activeClient)
            } catch {
                guard !Task.isCancelled else { return }
                AppDelegate.logger.error("Candidate lookup failed: \(error.localizedDescription, privacy: .public)")
                candidateWindow.hide()
            }
        }
    }

    private func refreshCandidateWindow(client: InputClient?) {
        mark(engine.displayText, client: client)
        guard !engine.currentPage.isEmpty else {
            candidateWindow.hide()
            return
        }
        candidateWindow.update()
        candidateWindow.show(kIMKLocateCandidatesBelowHint)
        candidateWindow.selectCandidate(engine.selectedIndex % CompositionEngine.pageSize)
    }

    private func apply(_ effect: CompositionEffect, client: InputClient?) {
        switch effect {
        case let .commit(text):
            insert(text, client: client)
        case .cancel:
            clearMarkedText(client: client)
        case .none, .needsCandidates:
            break
        }
        if !engine.isComposing {
            lookupTask?.cancel()
            candidateWindow.hide()
        }
    }

    private func mark(_ text: String, client: InputClient?) {
        guard let client else { return }
        let attributes = mark(forStyle: kTSMHiliteSelectedRawText, at: replacementRange())
            as? [NSAttributedString.Key: Any]
            ?? [.underlineStyle: NSUnderlineStyle.single.rawValue]
        let marked = NSAttributedString(string: text, attributes: attributes)
        client.setMarkedText(
            marked,
            selectionRange: NSRange(location: text.utf16.count, length: 0),
            replacementRange: replacementRange()
        )
    }

    private func clearMarkedText(client: InputClient?) {
        client?.setMarkedText(
            NSAttributedString(string: ""),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: replacementRange()
        )
    }

    private func insert(_ text: String, client: InputClient?) {
        guard !text.isEmpty else {
            clearMarkedText(client: client)
            return
        }
        client?.insertText(text as NSString, replacementRange: replacementRange())
        clearMarkedText(client: client)
    }
}
