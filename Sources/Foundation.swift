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
    
    init(NSObject: AnyObject) {
        switch NSObject {
        case let string as NSString: self = .String(string as Swift.String)
        case is NSNull: self = .Null
        case let dictionary as NSDictionary: 
            var parsedDictionary: [Swift.String: Value] = [:]
        
            for (key, value) in dictionary {
                if let key = key as? Swift.String {
                    parsedDictionary[key] = Value(NSObject: value)
                } else {
                    self = .Other(dictionary)
                    return
                }
            }
            
            self = .Dictionary(parsedDictionary)
        case let array as NSArray: self = .Array(array.map { Value(NSObject: $0) })
        case let set as NSSet: self = .Array(set.allObjects.map { Value(NSObject: $0) })
        case let decimal as NSDecimalNumber: self = .Double(decimal.doubleValue)
        case let number as NSNumber:
            switch Swift.String.fromCString(number.objCType)! {
            case "i", "l", "q" where number.longLongValue < Int64(Int.max): self = .Integer(number as Int)
            case "q", "d", "f": self = .Double(number as Swift.Double)
            case "B", "c", "i": self = .Boolean(number as Bool)
            default: self = .Other(number)
            }
        default: self = .Other(NSObject)
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
                dateFormatter.timeZone = dateFormatTimezone
                dateFormatter.locale = dateFormatLocale
                
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

public var dateFormatTimezone = NSTimeZone(abbreviation: "UTC")
public var dateFormatLocale = NSLocale(localeIdentifier: "en_US_POSIX")

public var dateFormatStrings = [
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'",
    "yyyy-MM-dd",
    "h:mm:ss A"
]