
import SwiftUI

struct SearchHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void
    let onRequestClearConfirmation: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !history.isEmpty {
                HStack(spacing: 12) {
                    Text(Localization.string("movies.recentSearches"))
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    Button {
                        onRequestClearConfirmation()
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(clearButtonBackground))
                            .overlay(Circle().stroke(chipBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Localization.string("movies.searchHistory.clear"))
                    .accessibilityIdentifier("movies.searchHistory.clearButton")
                }
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(history, id: \.self) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(chipBackground))
                                    .overlay(
                                        Capsule()
                                            .stroke(chipBorder, lineWidth: 1)
                                    )
                                    .shadow(color: chipShadow, radius: 8, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Localization.string("movies.accessibility.recentSearch", item))
                            .accessibilityIdentifier("movies.searchHistory.item.\(item)")
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .animation(.easeInOut(duration: 0.22), value: history)
    }

    private var chipBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color(.systemBackground)
    }

    private var clearButtonBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(.secondarySystemBackground)
    }

    private var chipBorder: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.16)
            : Color.black.opacity(0.08)
    }

    private var chipShadow: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.16)
            : Color.black.opacity(0.06)
    }
}
