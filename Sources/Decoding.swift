public enum DecodingError: ErrorType {
    case OutOfBounds(index: Int, array: [Value])
    case MissingKey(key: String, dictionary: [String: Value])
    case TypeMismatch(expectedType: Any.Type, value: Value)
    case InvalidData(data: Any)
}

public extension _ArrayType where Generator.Element == Value {
    func valueAt(index: Int) throws -> Value {
        guard index < count else { throw DecodingError.OutOfBounds(index: index, array: Array(self)) }
        
        return self[index]
    }
    
    func maybeValueAt(index: Int, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        guard index < count else {
            if throwOnMissing { throw DecodingError.OutOfBounds(index: index, array: Array(self)) }
            else { return nil }
        }
        
        let value = self[index]
        
        if nilOnNull && value == .Null { return nil }
        else { return value }
    }
}

public extension CollectionType where Generator.Element == (String, Value) {
    func valueFor(key: String) throws -> Value {
        let `self` = self as! [String: Value]
        
        guard let value = self[key] else { throw DecodingError.MissingKey(key: key, dictionary: self) }
        
        return value
    }
    
    func maybeValueFor(key: String, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        let `self` = self as! [String: Value]
        
        guard let value = self[key] else {
            if throwOnMissing { throw DecodingError.MissingKey(key: key, dictionary: self) }
            else { return nil }
        }
        
        if nilOnNull && value == .Null { return nil }
        else { return value }
    }
}

public extension Value {
    func valueAt(index: Int) throws -> Value {
        return try asArray().valueAt(index)
    }
    
    func maybeValueAt(index: Int, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        return try asArray().maybeValueAt(index, nilOnNull: nilOnNull, throwOnMissing: throwOnMissing)
    }
    
    func valueFor(key: Swift.String) throws -> Value {
        return try asDictionary().valueFor(key)
    }
    
    func maybeValueFor(key: Swift.String, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        return try asDictionary().maybeValueFor(key, nilOnNull: nilOnNull, throwOnMissing: throwOnMissing)
    }
}

public extension Value {
    func asBool() throws -> Bool {
        switch self {
        case let .Boolean(bool): return bool
        case let .String(string) where string == "true" || string == "false": return string == "true" ? true : false
        case let .Double(double) where double == 1 || double == 0: return double == 1 ? true : false
        case let .Integer(int) where int == 1 || int == 0: return int == 1 ? true : false
        case let .Other(other as Bool): return other
        default: throw DecodingError.TypeMismatch(expectedType: Bool.self, value: self)
        }
    }
    
    func asInt() throws -> Int {
        switch self {
        case let .Integer(int): return int
        case let .Double(double) where double < Swift.Double(Int.max): return Int(double)
        case let .Other(other as Int): return other
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
        case let .Other(other as Swift.Double): return other
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
        case let .Other(other as Swift.String): return other
        default: throw DecodingError.TypeMismatch(expectedType: Swift.String.self, value: self)
        }
    }
    
    private typealias _Array = Swift.Array<Value>
    
    func asArray() throws -> [Value] {
        switch self {
        case let .Array(array): return array
        case let .Other(other as _Array): return other
        default: throw DecodingError.TypeMismatch(expectedType: _Array.self, value: self)
        }
    }
    
    private typealias _Dictionary = Swift.Dictionary<Swift.String, Value>
    
    func asDictionary() throws -> [Swift.String: Value] {
        switch self {
        case let .Dictionary(dictionary): return dictionary
        case let .Other(other as _Dictionary): return other
        default: throw DecodingError.TypeMismatch(expectedType: _Dictionary.self, value: self)
        }
    }
    
    func asOther() throws -> Any {
        if case let .Other(other) = self { return other }
        else { throw DecodingError.TypeMismatch(expectedType: Any.self, value: self) }
    }
    
    func asOther<T>(type: T.Type = T.self) throws -> T {
        if case let .Other(other) = self, let value = other as? T { return value }
        else { throw DecodingError.TypeMismatch(expectedType: T.self, value: self) }
    }
}

public extension Value {
    func asFloat() throws -> Float {
        switch self {
        case let .Integer(int): return Float(int)
        case let .Double(double) /*where double < Swift.Double(Float.max)*/: return Float(double)
        case let .Other(other as Float): return other
        case let .String(string):
            if let float = Float(string) { return float }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: Float.self, value: self)
        }
    }
    
    func asInt64() throws -> Int64 {
        switch self {
        case let .Integer(int): return Int64(int)
        case let .Double(double) where double < Swift.Double(Int64.max): return Int64(double)
        case let .Other(other as Int64): return other
        case let .String(string):
            if let int64 = Int64(string) { return int64 }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: Int64.self, value: self)
        }
    }

    func asUInt() throws -> UInt {
        switch self {
        case let .Integer(int) where int >= 0: return UInt(int)
        case let .Double(double) where double >= 0 && double < Swift.Double(UInt.max): return UInt(double)
        case let .Other(other as UInt): return other
        case let .String(string):
            if let uint = UInt(string) { return uint }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: UInt.self, value: self)
        }
    }

    func asUInt64() throws -> UInt64 {
        switch self {
        case let .Integer(int) where int >= 0: return UInt64(int)
        case let .Double(double) where double >= 0 && double < Swift.Double(UInt64.max): return UInt64(double)
        case let .Other(other as UInt64): return other
        case let .String(string):
            if let uint64 = UInt64(string) { return uint64 }
            else { fallthrough }
        default: throw DecodingError.TypeMismatch(expectedType: UInt64.self, value: self)
        }
    }
    
    func asCharacter() throws -> Character {
        if case let .String(string) = self, let character = string.characters.first where string.characters.count == 1 {
            return character
        } else if case let .Other(other) = self where other is Character {
            return other as! Character
        } else { throw DecodingError.TypeMismatch(expectedType: Character.self, value: self) }
    }
}