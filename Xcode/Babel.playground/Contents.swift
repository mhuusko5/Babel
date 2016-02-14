import Babel

let jsonString = "{\"apiVersion\":\"2.0\",\n \"data\":{\n    \"updated\":\"2010-01-07T19:58:42.949Z\",\n    \"totalItems\":800,\n    \"startIndex\":1,\n    \"itemsPerPage\":1,\n    \"items\":[\n        {\"id\":\"hYB0mn5zh2c\",\n         \"uploaded\":\"2007-06-05T22:07:03.000Z\",\n         \"updated\":\"2010-01-07T13:26:50.000Z\",\n         \"uploader\":\"GoogleDeveloperDay\",\n         \"category\":\"News\",\n         \"title\":\"Google Developers Day US - Maps API Introduction\",\n         \"description\":\"Google Maps API Introduction ...\",\n         \"tags\":[\n            \"GDD07\",\"GDD07US\",\"Maps\"\n         ],\n         \"thumbnail\":{\n            \"default\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/default.jpg\",\n            \"hqDefault\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/hqdefault.jpg\"\n         },\n         \"player\":{\n            \"default\":\"http://www.youtube.com/watch?vu003dhYB0mn5zh2c\"\n         },\n         \"content\":{\n            \"1\":\"rtsp://v5.cache3.c.youtube.com/CiILENy.../0/0/0/video.3gp\",\n            \"5\":\"http://www.youtube.com/v/hYB0mn5zh2c?f...\",\n            \"6\":\"rtsp://v1.cache1.c.youtube.com/CiILENy.../0/0/0/video.3gp\"\n         },\n         \"duration\":2840,\n         \"aspectRatio\":\"widescreen\",\n         \"rating\":4.63,\n         \"ratingCount\":68,\n         \"viewCount\":220101,\n         \"favoriteCount\":201,\n         \"commentCount\":22,\n         \"status\":{\n            \"value\":\"restricted\",\n            \"reason\":\"limitedSyndication\"\n         },\n         \"accessControl\":{\n            \"syndicate\":\"allowed\",\n            \"commentVote\":\"allowed\",\n            \"rate\":\"allowed\",\n            \"list\":\"allowed\",\n            \"comment\":\"allowed\",\n            \"embed\":\"allowed\",\n            \"videoRespond\":\"moderated\"\n         }\n        }\n    ]\n }\n}"

enum ExampleType {
    case Operators
    case FunctionInferred
    case FunctionExplicit
    case Manual
}

let exampleType = ExampleType.Operators

public struct YouTubeResponse: Decodable {
    let apiVersion: Double
    let data: YouTubeData?
    
    public static func _decode(value: Value) throws -> YouTubeResponse {
        switch exampleType {
        case .Operators:
            return try YouTubeResponse(
                apiVersion: value => "apiVersion",
                data: value =>? "data"
            )
            
        case .FunctionInferred:
            return try YouTubeResponse(
                apiVersion: value.valueFor("apiVersion").decodeValue(),
                data: value.maybeValueFor("data")?.decodeValue()
            )
            
        case .FunctionExplicit:
            return try YouTubeResponse(
                apiVersion: value.valueFor("apiVersion").asDouble(),
                data: value.maybeValueFor("data", nilOnNull: true, throwOnMissing: true)?.decodeValue(type: YouTubeData.self)
            )
            
        case .Manual:
            let valueDictionary = try value.asDictionary()
            
            if let apiVersion = valueDictionary["apiVersion"]?.doubleValue /* Doesn't cover if valid Double in form of Int/String */ {
                if let data = valueDictionary["data"] {
                    if data.isNull {
                        return YouTubeResponse(apiVersion: apiVersion, data: nil)
                    } else {
                        return YouTubeResponse(apiVersion: apiVersion, data: try YouTubeData.decode(data))
                    }
                } else {
                    throw DecodingError.TypeMismatch(expectedType: YouTubeResponse.self, value: value)
                }
            } else {
                throw DecodingError.TypeMismatch(expectedType: YouTubeResponse.self, value: value)
            }
        }
    }
}

public struct YouTubeData: Decodable {
    let totalItems: Int
    let firstItem: YouTubeDataItem?
    let items: [YouTubeDataItem]
    
    public static func _decode(value: Value) throws -> YouTubeData {
        switch exampleType {
        case .Operators:
            return try YouTubeData(
                totalItems: value => "totalItems",
                firstItem: value => "items" =>?? 0,
                items: value => "items"
            )
            
        case .FunctionInferred:
            return try YouTubeData(
                totalItems: value.valueFor("totalItems").decodeValue(),
                firstItem: value.valueFor("items").maybeValueAt(0, throwOnMissing: false)?.decodeValue(),
                items: value.valueFor("items").decodeArray()
            )
            
        case .FunctionExplicit:
            return try YouTubeData(
                totalItems: value.valueFor("totalItems").asInt(),
                firstItem: value.valueFor("items").maybeValueAt(0, nilOnNull: true, throwOnMissing: false)?.decodeValue(type: YouTubeDataItem.self),
                items: value.valueFor("items").decodeArray(type: YouTubeDataItem.self)
            )
            
        case .Manual:
            let valueDictionary = try value.asDictionary()
            
            if let totalItems = valueDictionary["totalItems"]?.intValue,
               let items = valueDictionary["items"]?.arrayValue {
                
                let firstItem: YouTubeDataItem?
                if items.count > 0 && !items[0].isNull {
                    firstItem = try YouTubeDataItem.decode(items[0])
                } else { firstItem = nil }
                
                return YouTubeData(
                    totalItems: totalItems,
                    firstItem: firstItem,
                    items: try items.map { try YouTubeDataItem.decode($0) }
                )
            } else {
                throw DecodingError.TypeMismatch(expectedType: YouTubeData.self, value: value)
            }
        }
    }
}

public struct YouTubeDataItem: Decodable {
    let title: String
    let favouriteCount: Int
    let rating: Int
    let content: [String: NSURL]
    
    public static func _decode(value: Value) throws -> YouTubeDataItem {
        switch exampleType {
        case .Operators:
            return try YouTubeDataItem(
                title: value => "title",
                favouriteCount: value => "favoriteCount",
                rating: value => "rating",
                content: value => "content"
            )
            
        case .FunctionInferred:
            return try YouTubeDataItem(
                title: value.valueFor("title").decodeValue(),
                favouriteCount: value.valueFor("favoriteCount").decodeValue(),
                rating: value.valueFor("rating").decodeValue(),
                content: value.valueFor("content").decodeDictionary()
            )
            
        case .FunctionExplicit:
            return try YouTubeDataItem(
                title: value.valueFor("title").asString(),
                favouriteCount: value.valueFor("favoriteCount").asInt(),
                rating: value.valueFor("rating").asInt(),
                content: value.valueFor("content").decodeDictionary(type: NSURL.self)
            )
            
        case .Manual:
            let valueDictionary = try value.asDictionary()
            
            if let title = valueDictionary["title"]?.stringValue,
               let favouriteCount = valueDictionary["favoriteCount"]?.intValue,
               let rating = valueDictionary["rating"]?.intValue,
               let content = valueDictionary["content"]?.dictionaryValue {
                
                var decodedContent = [String: NSURL]()
                for (key, value) in content {
                    decodedContent[key] = try NSURL.decode(value)
                }
                
                return YouTubeDataItem(
                    title: title,
                    favouriteCount: favouriteCount,
                    rating: rating,
                    content: decodedContent
                )
            } else {
                throw DecodingError.TypeMismatch(expectedType: YouTubeDataItem.self, value: value)
            }
        }
    }
}

public struct NestingTest: Decodable {
    let value: [String: NSURL]
    
    public static func _decode(value: Value) throws -> NestingTest {
        return try NestingTest(
            value: (value =>? "data" => "items" =>?? 0 => "content") ?? [String: NSURL]()
        )
    }
}

let value = try! Value(JSON: jsonString)

print(debugDescription(value) + "\n\n")

print(debugDescription(value.nativeValue) + "\n\n")

do {
    print(debugDescription(try YouTubeResponse.decode(value)) + "\n\n")
} catch let error { print(debugDescription(error)) }

do {
    let content: [String: NSURL] = (try value =>? "data" => "items" =>?? 0 => "content") ?? [:]
    
    print(debugDescription(content) + "\n\n")
} catch let error { print(debugDescription(error)) }
