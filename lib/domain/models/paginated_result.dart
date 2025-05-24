class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final int currentPage;
  final int totalItems;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    required this.totalItems,
  });

  PaginatedResult<T> copyWith({
    List<T>? items,
    bool? hasMore,
    int? currentPage,
    int? totalItems,
  }) {
    return PaginatedResult<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}
