import Foundation

public typealias MetricHandler = (HTTPMetric) -> Void

public struct HTTPMetric: Codable {
    public let startAt: UInt64
    public let endAt: UInt64
    public let duration: Double
    public let responseStatusCode: Int
    public let requestUrl: String
    public let requestMethod: String
    public let requestRemoteAddress: String
    public let requestHeader: [String: String]
}
