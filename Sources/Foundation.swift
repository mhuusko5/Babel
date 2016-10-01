import Foundation

public extension Value {
    init(JSON: Data, encoding: String.Encoding = .utf8) throws {
        if let string = String(data: JSON, encoding: encoding) {
            try self.init(JSON: string)
        } else {
            throw DecodingError.invalidData(data: JSON)
        }
    }

    static func from(foundation value: Any?) -> Value {
        switch value {
        case nil: return .null
        case is NSNull: return .null
        case let string as NSString: return .string(string as String)
        case let dictionary as NSDictionary:
            var parsedDictionary = [String: Value](minimumCapacity: dictionary.count)

            for (key, value) in dictionary {
                if let key = key as? String {
                    parsedDictionary[key] = .from(foundation: value)
                } else {
                    return .other(dictionary)
                }
            }

            return .dictionary(parsedDictionary)
        case let array as NSArray: return .array(array.map { .from(foundation: $0) })
        case let set as NSSet: return .array(set.allObjects.map { .from(foundation: $0) })
        case let decimal as NSDecimalNumber: return .double(decimal.doubleValue)
        case let number as NSNumber:
            if CFBooleanGetTypeID() == CFGetTypeID(number) { return .boolean(number.boolValue) }

            switch CFNumberGetType(number) {
            case .intType, .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type,
                 .nsIntegerType, .cfIndexType,
                 .shortType, .longType, .longLongType:
                if number.int64Value < Int64(Int.max) {
                    return .integer(number.intValue)
                } else {
                    return .double(number.doubleValue)
                }
            case .floatType, .float32Type, .float64Type, .doubleType, .cgFloatType:
                return .double(number.doubleValue)
            case .charType: return .boolean(number.boolValue)
            }
        default: return .other(value)
        }
    }

    init(foundation value: Any?) {
        self = .from(foundation: value)
    }
}

public extension Decodable {
    static func decode(JSON: Data) throws -> Self {
        return try decode(Value(JSON: JSON))
    }
    
    static func decode(foundation value: Any?) throws -> Self {
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
