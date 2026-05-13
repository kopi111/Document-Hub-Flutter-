namespace JcfDocumentHub.Domain.Common;

public sealed class PagedResult<T>
{
    public required IReadOnlyList<T> Items { get; init; }

    public required int Page { get; init; }

    public required int PageSize { get; init; }

    public required long TotalItems { get; init; }

    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling(TotalItems / (double)PageSize) : 0;

    public static PagedResult<T> Empty(int page, int pageSize) => new()
    {
        Items = Array.Empty<T>(),
        Page = page,
        PageSize = pageSize,
        TotalItems = 0
    };
}
