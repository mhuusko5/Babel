import class Foundation.NSData
import class Foundation.NSDate
import class Foundation.NSURL
import class Foundation.NSDateFormatter
import class Foundation.NSTimeZone
import class Foundation.NSLocale

public extension Value {
    init(JSON: NSData, encoding: NSStringEncoding = NSUTF8StringEncoding) throws {
        if let string = Swift.String(data: JSON, encoding: encoding) {
            try self.init(JSON: string)
        } else {
            throw DecodingError.InvalidData(data: JSON)
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
            case "i", "l", "q":
                if number.longLongValue < Int64(Int.max) {
                    self = .Integer(number.integerValue)
                } else {
                    self = .Double(number.doubleValue)
                }
            case "q", "d", "f": self = .Double(number.doubleValue)
            case "B", "c": self = .Boolean(number.boolValue)
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
        if let string = value.stringValue, let data = string.dataUsingEncoding(dataStringEncoding) {
            return self.init(data: data)
        } else {
            throw DecodingError.TypeMismatch(expectedType: NSData.self, value: value)
        }
    }
}

public var dataStringEncoding = NSUTF8StringEncoding

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