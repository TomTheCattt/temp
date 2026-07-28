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
                    .withToast()
            } else {
                LoginView(
                    viewModel: AuthViewModel(
                        loginUseCase: DIContainer.shared.resolve(LoginUseCaseProtocol.self),
                        registerUseCase: DIContainer.shared.resolve(RegisterUseCaseProtocol.self)
                    )
                )
                .withToast()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
