import Foundation

public extension Value {
    init(JSON: Data, encoding: String.Encoding = .utf8) throws {
        if let string = String(data: JSON, encoding: encoding) {
            try self.init(JSON: string)
        } else {
            throw DecodingError.invalidData(data: JSON)
        }
    }
    
    init(foundation value: Any?) {
        switch value {
        case nil: self = .null
        case is NSNull: self = .null
        case let string as NSString: self = .string(string as String)
        case let dictionary as NSDictionary: 
            var parsedDictionary: [String: Value] = [:]
        
            for (key, value) in dictionary {
                if let key = key as? String {
                    parsedDictionary[key] = Value(foundation: value)
                } else {
                    self = .other(value)
                    return
                }
            }
            
            self = .dictionary(parsedDictionary)
        case let array as NSArray: self = .array(array.map { Value(foundation: $0) })
        case let set as NSSet: self = .array(set.allObjects.map { Value(foundation: $0) })
        case let decimal as NSDecimalNumber: self = .double(decimal.doubleValue)
        case let number as NSNumber:
            switch String(cString: number.objCType) {
            case "i", "l", "q":
                if number.int64Value < Int64(Int.max) {
                    self = .integer(number.intValue)
                } else {
                    self = .double(number.doubleValue)
                }
            case "q", "d", "f": self = .double(number.doubleValue)
            case "B", "c": self = .boolean(number.boolValue)
            default: self = .other(value)
            }
        default: self = .other(value)
        }
    }
}

public extension Decodable {
    static func decode(JSON: Data) throws -> Self {
        return try decode(Value(JSON: JSON))
    }
    
    static func decode(foundation value: Any) throws -> Self {
        return try decode(Value(foundation: value))
    }
}

extension URL: Decodable {
    public static func _decode(_ value: Value) throws -> URL {
        if let string = value.stringValue, let url = self.init(string: string) {
            return url
        } else {
            throw DecodingError.typeMismatch(expectedType: URL.self, value: value)
        }
    }
}

extension Data: Decodable {
    public static func _decode(_ value: Value) throws -> Data {
        if let string = value.stringValue, let data = string.data(using: dataStringEncoding) {
            return data
        } else {
            throw DecodingError.typeMismatch(expectedType: Data.self, value: value)
        }
    }
}

public var dataStringEncoding = String.Encoding.utf8

extension Date: Decodable {
    public static func _decode(_ value: Value) throws -> Date {
        if var dateInterval = try? value.asDouble(), dateInterval > 1000000000 {
            if dateInterval > 1000000000000 { dateInterval /= 1000 }
            
            return self.init(timeIntervalSince1970: dateInterval)
        } else if let dateString = value.stringValue {
            for format in dateFormatStrings {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = format
                dateFormatter.timeZone = dateFormatTimezone
                dateFormatter.locale = dateFormatLocale
                
                if let date = dateFormatter.date(from: dateString) {
                    return self.init(timeIntervalSince1970: date.timeIntervalSince1970)
                }
            }
            
            throw DecodingError.typeMismatch(expectedType: Date.self, value: value)
        } else {
            throw DecodingError.typeMismatch(expectedType: Date.self, value: value)
        }
    }
}

public var dateFormatTimezone = TimeZone(abbreviation: "UTC")
public var dateFormatLocale = Locale(identifier: "en_US_POSIX")

public var dateFormatStrings = [
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'",
    "yyyy-MM-dd",
    "h:mm:ss A"
]
