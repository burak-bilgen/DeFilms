
import SwiftUI

struct SearchHistoryView: View {
    let history: [String]
    let onSelect: (String) -> Void
    let onRequestClearConfirmation: () -> Void

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
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
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
                                    .lineLimit(1)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(AppPalette.elevatedBackground)
                                    .overlay(
                                        Capsule()
                                            .stroke(AppPalette.border, lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
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
}
