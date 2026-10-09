import SwiftUI
import NetworkExtension

@main
struct VPNTestApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var log: [String] = ["Tap the button. Watch for the Allow VPN popup."]
    var body: some View {
        VStack(spacing: 20) {
            Text("VPN Test").font(.largeTitle).bold()
            Button("Turn on VPN") { Task { await run() } }
                .font(.title2).padding().frame(maxWidth: .infinity)
                .background(Color.blue).foregroundColor(.white).cornerRadius(14)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(log.indices, id: \.self) { Text(log[$0]).font(.system(.body, design: .monospaced)) }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }.padding()
    }

    func add(_ s: String) { log.append(s) }

    func run() async {
        log = []
        let appID = Bundle.main.bundleIdentifier ?? "?"
        let tunnelID = appID + ".tunnel"
        add("App ID: \(appID)")
        let ent = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
        _ = ent
        do {
            let all = try await NETunnelProviderManager.loadAllFromPreferences()
            add("Step 1 load: OK (\(all.count) saved)")
            let m = all.first ?? NETunnelProviderManager()
            let p = NETunnelProviderProtocol()
            p.providerBundleIdentifier = tunnelID
            p.serverAddress = "127.0.0.1"
            m.protocolConfiguration = p
            m.localizedDescription = "CarScreen Test"
            m.isEnabled = true
            try await m.saveToPreferences()
            add("Step 2 save: OK  <-- VPN permission WORKS")
            try await m.loadFromPreferences()
            try m.connection.startVPNTunnel()
            add("Step 3 start: requested")
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            add("Status: \(m.connection.status.rawValue) (3 = connected)")
        } catch {
            let e = error as NSError
            add("FAILED: \(e.localizedDescription)")
            add("domain=\(e.domain) code=\(e.code)")
            add("Screenshot this and send it.")
        }
    }
}
