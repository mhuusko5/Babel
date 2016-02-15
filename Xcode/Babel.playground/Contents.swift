import Babel

let jsonString = "{\"apiVersion\":\"2.0\",\n \"data\":{\n    \"updated\":\"2010-01-07T19:58:42.949Z\",\n    \"totalItems\":800,\n    \"startIndex\":1,\n    \"itemsPerPage\":1,\n    \"items\":[\n        {\"id\":\"hYB0mn5zh2c\",\n         \"uploaded\":\"2007-06-05T22:07:03.000Z\",\n         \"updated\":\"2010-01-07T13:26:50.000Z\",\n         \"uploader\":\"GoogleDeveloperDay\",\n         \"category\":\"News\",\n         \"title\":\"Google Developers Day US - Maps API Introduction\",\n         \"description\":\"Google Maps API Introduction ...\",\n         \"tags\":[\n            \"GDD07\",\"GDD07US\",\"Maps\"\n         ],\n         \"thumbnail\":{\n            \"default\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/default.jpg\",\n            \"hqDefault\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/hqdefault.jpg\"\n         },\n         \"player\":{\n            \"default\":\"http://www.youtube.com/watch?vu003dhYB0mn5zh2c\"\n         },\n         \"content\":{\n            \"1\":\"rtsp://v5.cache3.c.youtube.com/CiILENy.../0/0/0/video.3gp\",\n            \"5\":\"http://www.youtube.com/v/hYB0mn5zh2c?f...\",\n            \"6\":\"rtsp://v1.cache1.c.youtube.com/CiILENy.../0/0/0/video.3gp\"\n         },\n         \"duration\":2840,\n         \"aspectRatio\":\"widescreen\",\n         \"rating\":4.63,\n         \"ratingCount\":68,\n         \"viewCount\":220101,\n         \"favoriteCount\":201,\n         \"commentCount\":22,\n         \"status\":{\n            \"value\":\"restricted\",\n            \"reason\":\"limitedSyndication\"\n         },\n         \"accessControl\":{\n            \"syndicate\":\"allowed\",\n            \"commentVote\":\"allowed\",\n            \"rate\":\"allowed\",\n            \"list\":\"allowed\",\n            \"comment\":\"allowed\",\n            \"embed\":\"allowed\",\n            \"videoRespond\":\"moderated\"\n         }\n        }\n    ]\n }\n}"

let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!

enum ExampleType {
    case Operators
    case FunctionInferred
    case FunctionExplicit
    case UnwrappingAndChecking
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
                apiVersion: value.valueFor("apiVersion").decode(),
                data: value.maybeValueFor("data")?.decode()
            )
            
        case .FunctionExplicit:
            return try YouTubeResponse(
                apiVersion: value.asDictionary().valueFor("apiVersion").asDouble(),
                data: value.asDictionary().maybeValueFor("data", nilOnNull: true, throwOnMissing: true)?.decode(type: YouTubeData.self)
            )
            
        case .UnwrappingAndChecking:
            let valueDictionary = try value.asDictionary()
            
            if let apiVersionString = valueDictionary["apiVersion"]?.stringValue,
                let apiVersion = Double(apiVersionString) {
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
                totalItems: value.valueFor("totalItems").decode(),
                firstItem: value.valueFor("items").maybeValueAt(0, throwOnMissing: false)?.decode(),
                items: value.valueFor("items").decodeArray()
            )
            
        case .FunctionExplicit:
            return try YouTubeData(
                totalItems: value.asDictionary().valueFor("totalItems").asInt(),
                firstItem: value.asDictionary().valueFor("items").asArray().maybeValueAt(0, nilOnNull: true, throwOnMissing: false)?.decode(type: YouTubeDataItem.self),
                items: value.asDictionary().valueFor("items").asArray().decode(type: YouTubeDataItem.self)
            )
            
        case .UnwrappingAndChecking:
            let valueDictionary = try value.asDictionary()
            
            if let totalItems = valueDictionary["totalItems"]?.intValue,
               let items = valueDictionary["items"]?.arrayValue {
                
                let firstItem: YouTubeDataItem?
                if items.count > 0 && !items[0].isNull {
                    firstItem = try YouTubeDataItem.decode(items[0])
                } else {
                    firstItem = nil
                }
                
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
    let content: [Int: NSURL]
    
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
                title: value.valueFor("title").decode(),
                favouriteCount: value.valueFor("favoriteCount").decode(),
                rating: value.valueFor("rating").decode(),
                content: value.valueFor("content").decodeDictionary()
            )
            
        case .FunctionExplicit:
            return try YouTubeDataItem(
                title: value.asDictionary().valueFor("title").asString(),
                favouriteCount: value.asDictionary().valueFor("favoriteCount").asInt(),
                rating: value.asDictionary().valueFor("rating").asInt(),
                content: value.asDictionary().valueFor("content").asDictionary().decode(keyType: Int.self, valueType: NSURL.self)
            )
            
        case .UnwrappingAndChecking:
            let valueDictionary = try value.asDictionary()
            
            if let title = valueDictionary["title"]?.stringValue,
               let favouriteCount = valueDictionary["favoriteCount"]?.intValue,
               let rating = valueDictionary["rating"]?.doubleValue.flatMap({ Int($0) }),
               let content = valueDictionary["content"]?.dictionaryValue {
                
                var decodedContent = [Int: NSURL]()
                for (key, value) in content {
                    if let intKey = Int(key) {
                        decodedContent[intKey] = try NSURL.decode(value)
                    } else {
                        throw DecodingError.TypeMismatch(expectedType: YouTubeDataItem.self, value: value)
                    }
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

let value = try! Value(JSON: jsonData) // or Value(JSON: jsonString)

prettyPrint(value)

prettyPrint(value.nativeValue)

do {
    prettyPrint(try YouTubeResponse.decode(value))
} catch let error { prettyPrint(error) }

do {
    // Such nesting, so simple, much semantic
    let content: [Int: NSURL] = (try value =>? "data" => "items" =>?? 0 => "content") ?? [:]
    
    prettyPrint(content)
} catch let error { prettyPrint(error) }
