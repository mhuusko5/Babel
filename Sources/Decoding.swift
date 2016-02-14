public enum DecodingError: ErrorType {
    case OutOfBounds(index: Int, array: [Value])
    case MissingKey(key: String, dictionary: [String: Value])
    case TypeMismatch(expectedType: Any.Type, value: Value)
}

public extension Value {
    func valueAt(index: Int) throws -> Value {
        let array = try asArray()
        
        guard index < array.count else { throw DecodingError.OutOfBounds(index: index, array: array) }
        
        return array[index]
    }
    
    func maybeValueAt(index: Int, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        let array = try asArray()
    
        guard index < array.count else {
            if throwOnMissing { throw DecodingError.OutOfBounds(index: index, array: array) }
            else { return nil }
        }
        
        let value = array[index]
        
        if nilOnNull, case .Null = value { return nil }
        else { return value }
    }
    
    func valueFor(key: Swift.String) throws -> Value {
        let dictionary = try asDictionary()
        
        guard let value = dictionary[key] else { throw DecodingError.MissingKey(key: key, dictionary: dictionary) }
        
        return value
    }
    
    func maybeValueFor(key: Swift.String, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        let dictionary = try asDictionary()
    
        guard let value = dictionary[key] else {
            if throwOnMissing { throw DecodingError.MissingKey(key: key, dictionary: dictionary) }
            else { return nil }
        }
        
        if nilOnNull, case .Null = value { return nil }
        else { return value }
    }
}

public extension Value {
    func asBool() throws -> Bool {
        switch self {
        case let .Boolean(bool): return bool
        case let .String(string) where string == "true" || string == "false": return string == "true" ? true : false
        case let .Integer(int) where int == 1 || int == 0: return int == 1 ? true : false
        default: throw DecodingError.TypeMismatch(expectedType: Bool.self, value: self)
        }
    }
    
    func asInt() throws -> Int {
        switch self {
        case let .Integer(int): return int
        case let .Double(double): return Int(double)
        case let .String(string):
            if let int = Int(string) { return int }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: Int.self, value: self)
        }
    }
    
    func asDouble() throws -> Swift.Double {
        switch self {
        case let .Double(double): return double
        case let .Integer(int): return Swift.Double(int)
        case let .String(string):
            if let double = Swift.Double(string) { return double }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: Swift.Double.self, value: self)
        }
    }
    
    func asString() throws -> Swift.String {
        switch self {
        case let .String(string): return string
        case let .Boolean(bool): return "\(bool)"
        case let .Integer(int): return "\(int)"
        case let .Double(double): return "\(double)"
        default: throw DecodingError.TypeMismatch(expectedType: Swift.String.self, value: self)
        }
    }
    
    private typealias _Array = Swift.Array<Value>
    
    func asArray() throws -> [Value] {
        if case let .Array(array) = self { return array }
        else { throw DecodingError.TypeMismatch(expectedType: _Array.self, value: self) }
    }
    
    private typealias _Dictionary = Swift.Dictionary<Swift.String, Value>
    
    func asDictionary() throws -> [Swift.String: Value] {
        if case let .Dictionary(dictionary) = self { return dictionary }
        else { throw DecodingError.TypeMismatch(expectedType: _Dictionary.self, value: self) }
    }
}

public extension Value {
    func asFloat() throws -> Float {
        switch self {
        case let .Integer(int): return Float(int)
        case let .Double(double): return Float(double)
        case let .String(string):
            if let float = Float(string) { return float }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: Float.self, value: self)
        }
    }
    
    func asInt64() throws -> Int64 {
        switch self {
        case let .Integer(int): return Int64(int)
        case let .Double(double): return Int64(double)
        case let .String(string):
            if let int64 = Int64(string) { return int64 }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: Int64.self, value: self)
        }
    }
    
    func asCharacter() throws -> Character {
        if case let .String(string) = self, let character = string.characters.first where string.characters.count == 1 {
            return character
        } else {
            throw DecodingError.TypeMismatch(expectedType: Character.self, value: self)
        }
    }
}