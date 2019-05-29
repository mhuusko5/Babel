import Babel

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

enum DataExample {
    case string
    case data
    case literal
    case literalShort
    case literalBadData
    case foundationObject
}

let dataExample = DataExample.string

enum DecodingExample {
    case operators
    case functionInferred
    case functionExplicit
    case unwrappingAndChecking
}

let decodingExample = DecodingExample.operators

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

let jsonString = "{\"apiVersion\":\"2.0\",\n \"data\":{\n    \"updated\":\"2010-01-07T19:58:42.949Z\",\n    \"totalItems\":800,\n    \"startIndex\":1,\n    \"itemsPerPage\":1,\n    \"items\":[\n        {\"id\":\"hYB0mn5zh2c\",\n         \"uploaded\":\"2007-06-05T22:07:03.000Z\",\n         \"updated\":\"2010-01-07T13:26:50.000Z\",\n         \"uploader\":\"GoogleDeveloperDay\",\n         \"category\":\"News\",\n         \"title\":\"Google Developers Day US - Maps API Introduction\",\n         \"description\":\"Google Maps API Introduction ...\",\n         \"tags\":[\n            \"GDD07\",\"GDD07US\",\"Maps\"\n         ],\n         \"thumbnail\":{\n            \"default\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/default.jpg\",\n            \"hqDefault\":\"http://i.ytimg.com/vi/hYB0mn5zh2c/hqdefault.jpg\"\n         },\n         \"player\":{\n            \"default\":\"http://www.youtube.com/watch?vu003dhYB0mn5zh2c\"\n         },\n         \"content\":{\n            \"1\":\"rtsp://v5.cache3.c.youtube.com/CiILENy.../0/0/0/video.3gp\",\n            \"5\":\"http://www.youtube.com/v/hYB0mn5zh2c?f...\",\n            \"6\":\"rtsp://v1.cache1.c.youtube.com/CiILENy.../0/0/0/video.3gp\"\n         },\n         \"duration\":2840,\n         \"aspectRatio\":\"widescreen\",\n         \"rating\":4.63,\n         \"ratingCount\":68,\n         \"viewCount\":220101,\n         \"favoriteCount\":201,\n         \"commentCount\":22,\n         \"status\":{\n            \"value\":\"restricted\",\n            \"reason\":\"limitedSyndication\"\n         },\n         \"accessControl\":{\n            \"syndicate\":\"allowed\",\n            \"commentVote\":\"allowed\",\n            \"rate\":\"allowed\",\n            \"list\":\"allowed\",\n            \"comment\":\"allowed\",\n            \"embed\":\"allowed\",\n            \"videoRespond\":\"moderated\"\n         }\n        }\n    ]\n }\n}"

let jsonData = jsonString.data(using: .utf8)!

let value: Value

switch dataExample {
case .string: value = try! Value(JSON: jsonString)
case .data: value = try! Value(JSON: jsonData)
case .literal:
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
case .literalShort:
    value = [
        "apiVersion": "2.0",
        "data": [
            "items": [],
            "totalItems": 0
        ]
    ]
case .literalBadData:
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
case .foundationObject:
    value = try! Value(foundation: JSONSerialization.jsonObject(with: jsonData, options: .allowFragments))
}

prettyPrint("Value: ", value)

prettyPrint("Native value: ", value.nativeValue)

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

public struct YouTubeResponse: Decodable {
    let apiVersion: Double
    let data: YouTubeData?
    
    public static func _decode(_ value: Value) throws -> YouTubeResponse {
        switch decodingExample {
        case .operators:
            return try YouTubeResponse(
                apiVersion: value => "apiVersion",
                data: value =>? "data"
            )
            
        case .functionInferred:
            return try YouTubeResponse(
                apiVersion: value.valueFor("apiVersion").decode(),
                data: value.maybeValueFor("data", throwOnMissing: true)?.decode()
            )
            
        case .functionExplicit:
            return try YouTubeResponse(
                apiVersion: value.asDictionary().valueFor("apiVersion").asDouble(),
                data: value.asDictionary().maybeValueFor("data", nilOnNull: true, throwOnMissing: true)?.decode(type: YouTubeData.self)
            )
            
        case .unwrappingAndChecking:
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
                    throw DecodingError.typeMismatch(expectedType: YouTubeResponse.self, value: value)
                }
            } else {
                throw DecodingError.typeMismatch(expectedType: YouTubeResponse.self, value: value)
            }
        }
    }
}

public struct YouTubeData: Decodable {
    let totalItems: Int
    let firstItem: YouTubeDataItem?
    let items: [YouTubeDataItem]
    
    public static func _decode(_ value: Value) throws -> YouTubeData {
        switch decodingExample {
        case .operators:
            return try YouTubeData(
                totalItems: value => "totalItems",
                firstItem: value => "items" =>?? 0,
                items: value => "items"
            )
            
        case .functionInferred:
            return try YouTubeData(
                totalItems: value.valueFor("totalItems").decode(),
                firstItem: value.valueFor("items").maybeValueAt(0)?.decode(),
                items: value.valueFor("items").decode()
            )
            
        case .functionExplicit:
            return try YouTubeData(
                totalItems: value.asDictionary().valueFor("totalItems").asInt(),
                firstItem: value.asDictionary().valueFor("items").asArray().maybeValueAt(0, nilOnNull: true, throwOnMissing: false)?.decode(type: YouTubeDataItem.self),
                items: value.asDictionary().valueFor("items").asArray().decode(type: YouTubeDataItem.self, ignoreFailures: false)
            )
            
        case .unwrappingAndChecking:
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
                throw DecodingError.typeMismatch(expectedType: YouTubeData.self, value: value)
            }
        }
    }
}

public struct YouTubeDataItem: Decodable {
    let title: String
    let favouriteCount: Int
    let rating: Int
    let uploaded: Date
    let content: [Int: URL]
    
    public static func _decode(_ value: Value) throws -> YouTubeDataItem {
        switch decodingExample {
        case .operators:
            return try YouTubeDataItem(
                title: value => "title",
                favouriteCount: value => "favoriteCount",
                rating: value => "rating",
                uploaded: value => "uploaded",
                content: value => "content"
            )
            
        case .functionInferred:
            return try YouTubeDataItem(
                title: value.valueFor("title").decode(),
                favouriteCount: value.valueFor("favoriteCount").decode(),
                rating: value.valueFor("rating").decode(),
                uploaded: value.valueFor("uploaded").decode(),
                content: value.valueFor("content").decode()
            )
            
        case .functionExplicit:
            return try YouTubeDataItem(
                title: value.asDictionary().valueFor("title").asString(),
                favouriteCount: value.asDictionary().valueFor("favoriteCount").asInt(),
                rating: value.asDictionary().valueFor("rating").asInt(),
                uploaded: value.asDictionary().valueFor("uploaded").decode(type: Date.self),
                content: value.asDictionary().valueFor("content").asDictionary().decode(keyType: Int.self, valueType: URL.self, ignoreFailures: false)
            )
            
        case .unwrappingAndChecking:
            let valueDictionary = try value.asDictionary()
            
            if let title = valueDictionary["title"]?.stringValue,
               let favouriteCount = valueDictionary["favoriteCount"]?.intValue,
               let rating = valueDictionary["rating"]?.doubleValue.flatMap({ Int($0) }),
               let content = valueDictionary["content"]?.dictionaryValue {
                
                var decodedContent = [Int: URL]()
                for (key, value) in content {
                    if let key = Int(key) {
                        decodedContent[key] = try URL.decode(value)
                    } else {
                        throw DecodingError.typeMismatch(expectedType: YouTubeDataItem.self, value: value)
                    }
                }
                
                let decodedUploaded: Date
                if let uploaded = valueDictionary["uploaded"], uploaded.isString {
                    decodedUploaded = try Date.decode(uploaded)
                } else {
                    throw DecodingError.typeMismatch(expectedType: YouTubeDataItem.self, value: value)
                }
                
                return YouTubeDataItem(
                    title: title,
                    favouriteCount: favouriteCount,
                    rating: rating,
                    uploaded: decodedUploaded,
                    content: decodedContent
                )
            } else {
                throw DecodingError.typeMismatch(expectedType: YouTubeDataItem.self, value: value)
            }
        }
    }
}

do {
    prettyPrint("Youtube response: ", try YouTubeResponse.decode(value))
} catch let error { prettyPrint("Youtube response error: ", error) }

// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

do {
    let content: [Int: URL]
    
    switch decodingExample {
    case .operators:
        content = (try value =>? "data" => "items" =>?? 0 => "content" as [Int: URL]?) ?? [:]
        
    case .functionInferred:
        content = (try value.maybeValueFor("data", throwOnMissing: true)?
                            .valueFor("items")
                            .maybeValueAt(0)?
                            .valueFor("content").decode()) ?? [:]
        
    case .functionExplicit:
        content = try value.asDictionary()
                           .maybeValueFor("data", nilOnNull: true, throwOnMissing: true)?.asDictionary()
                           .valueFor("items").asArray()
                           .maybeValueAt(0, nilOnNull: true, throwOnMissing: false)?.asDictionary()
                           .valueFor("content").asDictionary()
                           .decode(keyType: Int.self, valueType: URL.self, ignoreFailures: false) ?? [:]
        
    case .unwrappingAndChecking:
        var decodedContent: [Int: URL]?
        
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
                                                if let string = value.stringValue,
                                                    let url = URL(string: string) {
                                                    decodedContent![key] = url
                                                } else { throw DecodingError.typeMismatch(expectedType: URL.self, value: value) }
                                            } else { throw DecodingError.typeMismatch(expectedType: Int.self, value: .string(key)) }
                                        }
                                    } else { throw DecodingError.typeMismatch(expectedType: Dictionary<String, Value>.self, value: content) }
                                } else { throw DecodingError.missingKey(key: "content", dictionary: itemDictionary) }
                            } else { decodedContent = nil }
                        } else { throw DecodingError.typeMismatch(expectedType: Array<Value>.self, value: items) }
                    } else { throw DecodingError.missingKey(key: "items", dictionary: dataDictionary) }
                } else { throw DecodingError.typeMismatch(expectedType: Dictionary<String, Value>.self, value: data) }
            } else { throw DecodingError.missingKey(key: "data", dictionary: valueDictionary) }
        } else { throw DecodingError.typeMismatch(expectedType: Dictionary<String, Value>.self, value: value) }

        content = decodedContent ?? [:]
    }
    
    prettyPrint("Nested content: ", content)
} catch let error { prettyPrint("Nested content error: ", error) }
