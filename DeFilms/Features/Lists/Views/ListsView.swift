
import SwiftUI

struct ListsView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @EnvironmentObject private var coordinator: ListsCoordinator

    @ObservedObject var viewModel: ListsViewModel
    @State private var isCreateListPresented = false

    var body: some View {
        Group {
            if viewModel.lists.isEmpty {
                ListsEmptyState(
                    title: Localization.string("lists.empty.title"),
                    message: Localization.string(sessionManager.isSignedIn ? "lists.empty.signedIn" : "lists.empty.signedOut"),
                    actionTitle: Localization.string("lists.create.title")
                ) {
                    isCreateListPresented = true
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ListsSummaryCard(
                            listCount: viewModel.lists.count,
                            movieCount: viewModel.totalMovieCount
                        )

                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.lists) { list in
                                MovieListRow(
                                    list: list,
                                    openList: { coordinator.show(.list(list.id)) }
                                )
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(AppPalette.screenBackground)
                .animation(.easeInOut(duration: 0.22), value: viewModel.lists.map(\.id))
            }
        }
        .navigationTitle(Localization.string("lists.title"))
        .background(AppPalette.screenBackground)
        .animation(AppAnimation.standard, value: viewModel.lists.isEmpty)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isCreateListPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Localization.string("lists.create.title"))
                .accessibilityIdentifier("lists.create.button")
            }
        }
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                NewMovieListView(movie: nil)
            }
        }
    }
}
