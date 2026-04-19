//
//  ConnectionBlockingView.swift
//  DeFilms
//

import SwiftUI

struct ConnectionBlockingView: View {
    let isChecking: Bool
    let retryAction: () -> Void

    var body: some View {
        ZStack {
            AppPalette.screenBackground
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.78))
                    .padding(.bottom, AppSpacing.xs)

                VStack(spacing: AppSpacing.sm) {
                    Text(Localization.string("network.blocking.title"))
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(Localization.string("network.blocking.message"))
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: retryAction) {
                    HStack(spacing: AppSpacing.xs) {
                        if isChecking {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color(.systemBackground))
                        }

                        Text(
                            Localization.string(
                                isChecking
                                    ? "network.blocking.button.checking"
                                    : "network.blocking.button.retry"
                            )
                        )
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .disabled(isChecking)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 420)
            .appElevatedSurface(cornerRadius: AppCornerRadius.xl, background: AppPalette.cardBackground)
            .padding(.horizontal, AppSpacing.xl)
        }
    }
}
