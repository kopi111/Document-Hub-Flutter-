namespace JcfDocumentHub.Application.Common;

public sealed record PageRequest
{
    private const int DefaultPage = 1;
    private const int DefaultPageSize = 50;
    private const int MaximumPageSize = 100;

    public int Page { get; init; } = DefaultPage;

    public int PageSize { get; init; } = DefaultPageSize;

    public static PageRequest Normalise(int? page, int? pageSize)
    {
        int requestedPage = page is null or < 1 ? DefaultPage : page.Value;
        int requestedSize = pageSize switch
        {
            null or < 1 => DefaultPageSize,
            > MaximumPageSize => MaximumPageSize,
            _ => pageSize.Value
        };
        return new PageRequest { Page = requestedPage, PageSize = requestedSize };
    }
}
