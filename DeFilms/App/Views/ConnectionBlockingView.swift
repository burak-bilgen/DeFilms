//
//  ConnectionBlockingView.swift
//  DeFilms
//

import SwiftUI

struct ConnectionBlockingView: View {
    @EnvironmentObject private var preferences: AppPreferences

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
                    Text(copy.title)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(copy.message)
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

                        Text(copy.buttonTitle)
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

    private var copy: ConnectionBlockingCopy {
        switch preferences.selectedLanguage {
        case .english:
            return ConnectionBlockingCopy(
                title: "Internet connection required",
                message: "DeFilms needs an active Wi-Fi or cellular connection to load movie data. Reconnect to the internet and try again.",
                buttonTitle: isChecking ? "Checking..." : "Check Again"
            )
        case .turkish:
            return ConnectionBlockingCopy(
                title: "Internet baglantisi gerekli",
                message: "DeFilms film verilerini yuklemek icin aktif bir Wi-Fi veya mobil veri baglantisina ihtiyac duyar. Baglantiyi geri getirip tekrar deneyin.",
                buttonTitle: isChecking ? "Kontrol ediliyor..." : "Tekrar Kontrol Et"
            )
        case .arabic:
            return ConnectionBlockingCopy(
                title: "الاتصال بالانترنت مطلوب",
                message: "يحتاج DeFilms الى اتصال فعال عبر الواي فاي او البيانات الخلوية لتحميل بيانات الافلام. اعد الاتصال ثم حاول مرة اخرى.",
                buttonTitle: isChecking ? "جار التحقق..." : "اعادة التحقق"
            )
        }
    }
}

private struct ConnectionBlockingCopy {
    let title: String
    let message: String
    let buttonTitle: String
}
