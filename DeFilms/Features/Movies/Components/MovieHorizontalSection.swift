
import SwiftUI

struct MovieHorizontalSection: View {
    @EnvironmentObject private var coordinator: MovieCoordinator
    let title: String
    let movies: [Movie]
    let isLoadingMore: Bool
    let onLoadMore: ((Movie, [Movie]) -> Void)?

    init(
        title: String,
        movies: [Movie],
        isLoadingMore: Bool = false,
        onLoadMore: ((Movie, [Movie]) -> Void)? = nil
    ) {
        self.title = title
        self.movies = movies
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, AppSpacing.md)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: AppSpacing.lg + 2) {
                    ForEach(movies) { movie in
                        MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                            coordinator.show(.detail(movie))
                        }
                        .onAppear {
                            onLoadMore?(movie, movies)
                        }
                    }

                    if isLoadingMore {
                        ProgressView()
                            .frame(width: AppDimension.posterRailWidth, height: 236)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs - 2)
                .animation(.easeInOut(duration: 0.2), value: isLoadingMore)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
