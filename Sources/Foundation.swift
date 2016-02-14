import Foundation

public extension Value {
    init(JSON: NSData) throws {
        if let string = Swift.String(data: JSON, encoding: NSUTF8StringEncoding) {
            self = try JSONParser(string.utf8).parse()
        } else {
            throw ParsingError.InvalidData
        }
    }
}

extension NSURL: Decodable {
    public static func _decode(value: Value) throws -> Self {
        if let url = try self.init(string: value.asString()) {
            return url
        } else {
            throw DecodingError.TypeMismatch(expectedType: NSURL.self, value: value)
        }
    }
}

extension NSData: Decodable {
    public static func _decode(value: Value) throws -> Self {
        if let data = try value.asString().dataUsingEncoding(NSUTF8StringEncoding) {
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
        } else if let dateString = try? value.asString() {
            for format in dateFormatStrings {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = format
                dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                
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

public var dateFormatStrings = [
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd'T'HH:mm:ss'Z'",
    "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'",
    "yyyy-MM-dd",
    "h:mm:ss A"
]