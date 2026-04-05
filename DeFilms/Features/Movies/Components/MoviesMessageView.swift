//
//  MoviesMessageView.swift
//  DeFilms
//

import Lottie
import SwiftUI

struct MoviesMessageView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    var animationName: String? = nil

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            if let animationName {
                MoviesLottieView(animationName: animationName)
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(PrimaryProminentButtonStyle())
            }
        }
        .padding(AppSpacing.xl)
        .appCardSurface(cornerRadius: AppCornerRadius.md)
        .accessibilityElement(children: .contain)
    }
}

private struct MoviesLottieView: UIViewRepresentable {
    let animationName: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }
        if animationView.isAnimationPlaying == false {
            animationView.play()
        }
    }
}
