
using System.Collections.Generic;

namespace Models;
public struct SearchResult
{
    public Value<WebpageResult> webPages { get; set; }
    public Value<NewsResult> news { get; set; }
    public Value<ImageResult> images { get; set; }
    public Value<VideoResult> videos { get; set; }
}

public struct Value<T>
{
    public List<T> value { get; set; }

}
public struct WebpageResult
{
    public string name { get; set; }
    public string description { get; set; }
    public string url { get; set; }
}
public struct NewsResult
{
    public string name { get; set; }
    public string description { get; set; }
    public string url { get; set; }
}
public struct ImageResult
{
    public string name { get; set; }
    public string contentUrl { get; set; }
}
public struct VideoResult
{
    public string name { get; set; }
    public string description { get; set; }
    public string contentUrl { get; set; }
}