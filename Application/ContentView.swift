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
                        loginUseCase: LoginUseCase(authRepository: AuthRepository()),
                        registerUseCase: RegisterUseCase(authRepository: AuthRepository())
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
