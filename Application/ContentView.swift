//
//  ContentView.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import SwiftUI

struct ContentView: View {

    @State private var router = AppRouter.shared

    var body: some View {
        Group {
            if router.isAuthenticated {
                MainTabView()
            } else {
                LoginView(
                    viewModel: DIContainer.shared.resolve(AuthViewModel.self)
                )
            }
        }
        .animation(DS.Animation.smooth, value: router.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
