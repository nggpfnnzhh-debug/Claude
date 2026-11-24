import SwiftUI

@main
struct LernlaborApp: App {
    @State private var model = AppModel()
    @State private var purchases = Purchases()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(purchases)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            HomeView()
                .tabItem { Label("Start", systemImage: "house") }
                .tag(AppTab.start)
            LabView()
                .tabItem { Label("Labor", systemImage: "testtube.2") }
                .tag(AppTab.lab)
            MythsView()
                .tabItem { Label("Wissen", systemImage: "book") }
                .tag(AppTab.knowledge)
            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
    }
}
