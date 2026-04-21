import SwiftUI
import A2UI
import A2UISkills

/// Minimal chat UI on top of SkillRuntime + A2UISurfaceView.
struct StarterChatView: View {
    @Environment(SkillRuntime.self) var runtime
    @State private var composerText: String = ""

    /// Optional error message to show above the composer (e.g. missing API key).
    let startupError: String?

    /// A dummy A2UIClient — A2UISurfaceView's components expect an A2UIClient
    /// in the environment for event dispatch. We intercept clicks and hand
    /// them to SkillRuntime via a passthrough client subclass below.
    @State private var shim: SkillRuntimeClientShim

    init(startupError: String?) {
        self.startupError = startupError
        _shim = State(initialValue: SkillRuntimeClientShim())
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            transcript
            composer
        }
        .background(Color(white: 0.98))
        .environment(shim.client)
        .task {
            // Wire the shim once the runtime environment is ready.
            shim.attach(runtime: runtime)
        }
    }

    private var header: some View {
        HStack {
            Text("A2UI Starter")
                .font(.system(size: 18, weight: .bold))
                .tracking(-0.2)
            Spacer()
            Text("client-side skills · Claude-powered")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    ForEach(runtime.turns) { turn in
                        turnView(turn).id(turn.id)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let err = runtime.lastError {
                        Text(err).font(.system(size: 12)).foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20).padding(.vertical, 20)
            }
            .onChange(of: runtime.turns.count) { _, _ in
                if let id = runtime.turns.last?.id {
                    withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            if let err = startupError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.orange.opacity(0.08))
            }
            HStack(spacing: 8) {
                TextField("Type anything…", text: $composerText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color(white: 0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onSubmit(sendText)
                Button { sendText() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(composerText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.white)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
            }
        }
    }

    @ViewBuilder
    private func turnView(_ turn: ChatTurn) -> some View {
        switch turn {
        case .agent(let sid):
            if let surface = runtime.surfaces[sid],
               surface.component("root") != nil {
                HStack { A2UISurfaceView(surface: surface, rootComponentId: "root"); Spacer(minLength: 0) }
            } else {
                HStack { ThinkingDots(); Spacer(minLength: 0) }
            }
        case .user(let text):
            HStack {
                Spacer(minLength: 0)
                Text(text)
                    .font(.system(size: 15)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        case .userPill(let label):
            HStack {
                Spacer(minLength: 0)
                Text(label)
                    .font(.system(size: 14).italic())
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(white: 0.90))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        case .thinking:
            HStack { ThinkingDots(); Spacer(minLength: 0) }
        }
    }

    private func sendText() {
        let t = composerText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        runtime.handleUserText(t)
        composerText = ""
    }
}

// MARK: - Shim to bridge A2UIClient events into the runtime

/// A2UISurfaceView dispatches button/option taps via the A2UIClient in its
/// SwiftUI environment. We don't want a real WebSocket; this shim intercepts
/// those calls and forwards them to SkillRuntime.
@MainActor
final class SkillRuntimeClientShim {
    let client: A2UIClient
    private var runtime: SkillRuntime?
    private var observer: NSObjectProtocol?

    init() {
        // A2UIClient needs a URL; pass a dummy — we override send paths.
        self.client = ShimClient(url: URL(string: "ws://127.0.0.1:0/noop")!)
    }

    func attach(runtime: SkillRuntime) {
        self.runtime = runtime
        (client as? ShimClient)?.onEvent = { [weak runtime] name, context, echoLabel in
            runtime?.handleUserEvent(name: name, context: context, echoLabel: echoLabel)
        }
        (client as? ShimClient)?.onText = { [weak runtime] text in
            runtime?.handleUserText(text)
        }
    }
}

/// A2UIClient subclass that redirects sends into callbacks instead of WebSocket.
final class ShimClient: A2UIClient, @unchecked Sendable {
    var onEvent: (@MainActor (String, [String: JSONValue], String?) -> Void)?
    var onText: (@MainActor (String) -> Void)?

    override func sendEvent(name: String, context: [String: JSONValue] = [:], echoLabel: String? = nil) {
        Task { @MainActor in self.onEvent?(name, context, echoLabel) }
    }
    override func sendText(_ text: String) {
        Task { @MainActor in self.onText?(text) }
    }
}

struct ThinkingDots: View {
    @State private var t: Double = 0
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: offset(for: i))
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) { t = 1.0 }
        }
    }
    private func offset(for i: Int) -> CGFloat {
        let phase = (t - Double(i) * 0.15).truncatingRemainder(dividingBy: 1.0)
        return phase < 0.4 ? -5 * CGFloat(phase / 0.4) : -5 * CGFloat(1 - (phase - 0.4) / 0.6)
    }
}
