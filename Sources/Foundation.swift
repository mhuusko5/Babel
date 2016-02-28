import class Foundation.NSData
import class Foundation.NSDate
import class Foundation.NSURL
import class Foundation.NSDateFormatter
import class Foundation.NSLocale

public extension Value {
    init(JSON: NSData) throws {
        if let string = Swift.String(data: JSON, encoding: NSUTF8StringEncoding) {
            self = try JSONParser(string.utf8).parse()
        } else {
            throw ParsingError.InvalidData
        }
    }
    
    init(NSObject: AnyObject) throws {
        switch NSObject {
        case let string as NSString: self = .String(string as Swift.String)
        case is NSNull: self = .Null
        case let dictionary as NSDictionary: 
            var parsedDictionary: [Swift.String: Value] = [:]
        
            for (key, value) in dictionary {
                if let key = key as? Swift.String {
                    parsedDictionary[key] = try Value(NSObject: value)
                } else { throw ParsingError.InvalidData }
            }
            
            self = .Dictionary(parsedDictionary)
        case let array as NSArray: self = try .Array(array.map { try Value(NSObject: $0) })
        case let number as NSNumber:
            switch Swift.String.fromCString(number.objCType)! {
            case "i", "l", "q" where number.longLongValue < Int64(Int.max): self = .Integer(number as Int)
            case "q", "d", "f": self = .Double(number as Swift.Double)
            case "B", "c", "i": self = .Boolean(number as Bool)
            default: throw ParsingError.InvalidData
            }
        default: throw ParsingError.InvalidData
        }
    }
}

public extension Decodable {
    static func decode(JSON JSON: NSData) throws -> Self {
        return try decode(Value(JSON: JSON))
    }
    
    static func decode(NSObject NSObject: AnyObject) throws -> Self {
        return try decode(Value(NSObject: NSObject))
    }
}

extension NSURL: Decodable {
    public static func _decode(value: Value) throws -> Self {
        if let string = value.stringValue, let url = self.init(string: string) {
            return url
        } else {
            throw DecodingError.TypeMismatch(expectedType: NSURL.self, value: value)
        }
    }
}

extension NSData: Decodable {
    public static func _decode(value: Value) throws -> Self {
        if let string = value.stringValue, let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            return self.init(data: data)
        } else {
            throw DecodingError.TypeMismatch(expectedType: NSData.self, value: value)
        }
    }
}

extension NSDate: Decodable {
    public static func _decode(value: Value) throws -> Self {
        if var dateInterval = try? value.asDouble() where dateInterval > 1000000000 {
            if dateInterval > 1000000000000 { dateInterval /= 1000 }
            
            return self.init(timeIntervalSince1970: dateInterval)
        } else if let dateString = value.stringValue {
            for format in dateFormatStrings {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = format
                dateFormatter.locale = NSLocale(localeIdentifier: dataFormatLocale)
                
                if let date = dateFormatter.dateFromString(dateString) {
                    return self.init(timeIntervalSince1970: date.timeIntervalSince1970)
                }
            }
            
            throw DecodingError.TypeMismatch(expectedType: NSDate.self, value: value)
        } else {
            throw DecodingError.TypeMismatch(expectedType: NSDate.self, value: value)
        }
    }
}

public var dataFormatLocale = "en_US_POSIX"

public var dateFormatStrings = [
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'",
    "yyyy-MM-dd",
    "h:mm:ss A"
]