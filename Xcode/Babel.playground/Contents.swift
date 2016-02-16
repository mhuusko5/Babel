import Babel

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

enum DataExample {
    case String
    case Data
    case Literal
    case LiteralShort
    case LiteralBadData
}

let dataExample = DataExample.String

enum DecodingExample {
    case Operators
    case FunctionInferred
    case FunctionExplicit
    case UnwrappingAndChecking
}

let decodingExample = DecodingExample.Operators

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

let jsonString = "{\"apiVersion\":\"2.0\",\n \"data\":{\n    \"updated\":\"2010-01-07T19:58:42.949Z\",\n    \"totalItems\":800,\n    \"startIndex\":1,\n    \"itemsPerPage\":1,\n    \"items\":[\n        {\"id\":\"hYB0mn5zh2c\",\n         \"uploaded\":\"2007-06-05T22:07:03.000Z\",\n         \"updated\":\"2010-01-07T13:26:50.000Z\",\n         \"uploader\":\"GoogleDeveloperDay\",\n         \"category\":\"News\",\n         \"title\":\"Google Developers Day US - Maps API Introduction\",\n         \"description\":\"Google Maps API Introduction ...\",\n         \"tags\":[\n            \"GDD07\",\"GDD07US\",\"Maps\"\n         ],\n         \"thumbnail\":{\n            \"default\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/default.jpg\",\n            \"hqDefault\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/hqdefault.jpg\"\n         },\n         \"player\":{\n            \"default\":\"http://www.youtube.com/watch?vu003dhYB0mn5zh2c\"\n         },\n         \"content\":{\n            \"1\":\"rtsp://v5.cache3.c.youtube.com/CiILENy.../0/0/0/video.3gp\",\n            \"5\":\"http://www.youtube.com/v/hYB0mn5zh2c?f...\",\n            \"6\":\"rtsp://v1.cache1.c.youtube.com/CiILENy.../0/0/0/video.3gp\"\n         },\n         \"duration\":2840,\n         \"aspectRatio\":\"widescreen\",\n         \"rating\":4.63,\n         \"ratingCount\":68,\n         \"viewCount\":220101,\n         \"favoriteCount\":201,\n         \"commentCount\":22,\n         \"status\":{\n            \"value\":\"restricted\",\n            \"reason\":\"limitedSyndication\"\n         },\n         \"accessControl\":{\n            \"syndicate\":\"allowed\",\n            \"commentVote\":\"allowed\",\n            \"rate\":\"allowed\",\n            \"list\":\"allowed\",\n            \"comment\":\"allowed\",\n            \"embed\":\"allowed\",\n            \"videoRespond\":\"moderated\"\n         }\n        }\n    ]\n }\n}"

let jsonData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!

let value: Value

switch dataExample {
case .String: value = try! Value(JSON: jsonString)
case .Data: value = try! Value(JSON: jsonData)
case .Literal:
    value = [
        "apiVersion": "2.0",
        "data": [
            "items": [
                [
                    "title": "Google Developers Day US - Maps API Introduction",
                    "content": [
                        "5": "http://www.youtube.com/v/hYB0mn5zh2c?f...",
                        "6": "rtsp://v1.cache1.c.youtube.com/CiILENy.../0/0/0/video.3gp",
                        "1": "rtsp://v5.cache3.c.youtube.com/CiILENy.../0/0/0/video.3gp"
                    ],
                    "favoriteCount": 201,
                    "rating": 4.63,
                    "uploaded": "2007-06-05T22:07:03.000Z"
                ],
                [
                    "title": "RANDOM",
                    "content": [
                        "1": "rtsp://v5.cache3.c.youtube.com/CiILENy.../0/0/0/video.3gp"
                    ],
                    "favoriteCount": 180,
                    "rating": 2.00,
                    "uploaded": "2007-06-05T22:07:03.000Z"
                ]
            ],
            "totalItems": 800
        ]
    ]
case .LiteralShort:
    value = [
        "apiVersion": "2.0",
        "data": [
            "items": [],
            "totalItems": 0
        ]
    ]
case .LiteralBadData:
    value = [
        "apiVersion": "2.0",
        "data": [
            "items": [
                [
                    "title": "Google Developers Day US - Maps API Introduction",
                    "content": nil,
                    "favoriteCount": 201,
                    "rating": 4.63,
                    "uploaded": "2007-06-05T22:07:03.000Z"
                ]
            ],
            "totalItems": 800
        ]
    ]
}

prettyPrint("Value: ", value)

prettyPrint("Native value: ", value.nativeValue)

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

public struct YouTubeResponse: Decodable {
    let apiVersion: Double
    let data: YouTubeData?
    
    public static func _decode(value: Value) throws -> YouTubeResponse {
        switch decodingExample {
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
                data: value.asDictionary().maybeValueFor("data", nilOnNull: true, throwOnMissing: true)?.decode(type: YouTubeData.self, ignoreFailure: false)
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
        switch decodingExample {
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
                items: value.valueFor("items").decode()
            )
            
        case .FunctionExplicit:
            return try YouTubeData(
                totalItems: value.asDictionary().valueFor("totalItems").asInt(),
                firstItem: value.asDictionary().valueFor("items").asArray().maybeValueAt(0, nilOnNull: true, throwOnMissing: false)?.decode(type: YouTubeDataItem.self, ignoreFailure: false),
                items: value.asDictionary().valueFor("items").asArray().decode(type: YouTubeDataItem.self, ignoreFailures: false)
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
    let uploaded: NSDate
    let content: [Int: NSURL]
    
    public static func _decode(value: Value) throws -> YouTubeDataItem {
        switch decodingExample {
        case .Operators:
            return try YouTubeDataItem(
                title: value => "title",
                favouriteCount: value => "favoriteCount",
                rating: value => "rating",
                uploaded: value => "uploaded",
                content: value => "content"
            )
            
        case .FunctionInferred:
            return try YouTubeDataItem(
                title: value.valueFor("title").decode(),
                favouriteCount: value.valueFor("favoriteCount").decode(),
                rating: value.valueFor("rating").decode(),
                uploaded: value.valueFor("uploaded").decode(),
                content: value.valueFor("content").decode()
            )
            
        case .FunctionExplicit:
            return try YouTubeDataItem(
                title: value.asDictionary().valueFor("title").asString(),
                favouriteCount: value.asDictionary().valueFor("favoriteCount").asInt(),
                rating: value.asDictionary().valueFor("rating").asInt(),
                uploaded: value.asDictionary().valueFor("uploaded").decode(type: NSDate.self),
                content: value.asDictionary().valueFor("content").asDictionary().decode(keyType: Int.self, valueType: NSURL.self, ignoreFailures: false)
            )
            
        case .UnwrappingAndChecking:
            let valueDictionary = try value.asDictionary()
            
            if let title = valueDictionary["title"]?.stringValue,
               let favouriteCount = valueDictionary["favoriteCount"]?.intValue,
               let rating = valueDictionary["rating"]?.doubleValue.flatMap({ Int($0) }),
               let content = valueDictionary["content"]?.dictionaryValue {
                
                var decodedContent = [Int: NSURL]()
                for (key, value) in content {
                    if let key = Int(key) {
                        decodedContent[key] = try NSURL.decode(value)
                    } else {
                        throw DecodingError.TypeMismatch(expectedType: YouTubeDataItem.self, value: value)
                    }
                }
                
                let decodedUploaded: NSDate
                if let uploaded = valueDictionary["uploaded"] where uploaded.isString {
                    decodedUploaded = try NSDate.decode(uploaded)
                } else {
                    throw DecodingError.TypeMismatch(expectedType: YouTubeDataItem.self, value: value)
                }
                
                return YouTubeDataItem(
                    title: title,
                    favouriteCount: favouriteCount,
                    rating: rating,
                    uploaded: decodedUploaded,
                    content: decodedContent
                )
            } else {
                throw DecodingError.TypeMismatch(expectedType: YouTubeDataItem.self, value: value)
            }
        }
    }
}

do {
    prettyPrint("Youtube response: ", try YouTubeResponse.decode(value))
} catch let error { prettyPrint("Youtube response error: ", error) }

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

do {
    let content: [Int: NSURL]
    
    switch decodingExample {
    case .Operators:
        content = (try value =>? "data" => "items" =>?? 0 => "content") ?? [:]
        
    case .FunctionInferred:
        content = (try value.maybeValueFor("data")?.valueFor("items").maybeValueAt(0, throwOnMissing: false)?.valueFor("content").decode()) ?? [:]
        
    case .FunctionExplicit:
        content = try value.asDictionary()
                           .maybeValueFor("data", nilOnNull: true, throwOnMissing: true)?.asDictionary()
                           .valueFor("items").asArray()
                           .maybeValueAt(0, nilOnNull: true, throwOnMissing: false)?.asDictionary()
                           .valueFor("content").asDictionary()
                           .decode(keyType: Int.self, valueType: NSURL.self, ignoreFailures: false) ?? [:]
        
    case .UnwrappingAndChecking:
        var decodedContent: [Int: NSURL]?
        
        if let valueDictionary = value.dictionaryValue {
            if let data = valueDictionary["data"] {
                if data.isNull {
                    decodedContent = nil
                } else if let dataDictionary = data.dictionaryValue {
                    if let items = dataDictionary["items"] {
                        if let itemsArray = items.arrayValue {
                            if itemsArray.count > 0 && itemsArray[0].isDictionary {
                                let itemDictionary = itemsArray[0].dictionaryValue!

                                if let content = itemDictionary["content"] {
                                    if let contentDictionary = content.dictionaryValue {
                                        decodedContent = [:]
                                        
                                        for (key, value) in contentDictionary {
                                            if let key = Int(key) {
                                                if let string = value.stringValue, url = NSURL(string: string) {
                                                    decodedContent![key] = url
                                                } else { throw DecodingError.TypeMismatch(expectedType: NSURL.self, value: value) }
                                            } else { throw DecodingError.TypeMismatch(expectedType: Int.self, value: .String(key)) }
                                        }
                                    } else { throw DecodingError.TypeMismatch(expectedType: Dictionary<String, Value>.self, value: content) }
                                } else { throw DecodingError.MissingKey(key: "content", dictionary: itemDictionary) }
                            } else { decodedContent = nil }
                        } else { throw DecodingError.TypeMismatch(expectedType: Array<Value>.self, value: items) }
                    } else { throw DecodingError.MissingKey(key: "items", dictionary: dataDictionary) }
                } else { throw DecodingError.TypeMismatch(expectedType: Dictionary<String, Value>.self, value: data) }
            } else { throw DecodingError.MissingKey(key: "data", dictionary: valueDictionary) }
        } else { throw DecodingError.TypeMismatch(expectedType: Dictionary<String, Value>.self, value: value) }

        content = decodedContent ?? [:]
    }
    
    prettyPrint("Nested content: ", content)
} catch let error { prettyPrint("Nested content error: ", error) }
