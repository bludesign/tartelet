import Foundation
import GitHubDomain
import Observation
import SettingsDomain
import SwiftUI

struct WebhookSettingsView<SettingsStoreType: SettingsStore & Observable>: View {
    @Bindable var settingsStore: SettingsStoreType
    let isSettingsEnabled: Bool

    @State private var webhookPort = ""

    var body: some View {
        Form {
            Section {
                TextField(L10n.Settings.Webhook.port, text: $webhookPort)
                    .disabled(!isSettingsEnabled)
                Text(L10n.Settings.Webhook.Port.subtitle)
                Toggle(isOn: $settingsStore.insecurePull) {
                    Text(L10n.Settings.Webhook.insecurePulls)
                }
                .disabled(!isSettingsEnabled)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            webhookPort = settingsStore.webhookPort ?? ""
        }
        .onChange(of: webhookPort) { _, newValue in
            guard !newValue.isEmpty, Int(newValue) != nil else {
                settingsStore.webhookPort = nil
                return
            }
            settingsStore.webhookPort = newValue
        }
    }
}
