public enum DecodingError: Error {
    case outOfBounds(index: Int, array: [Value])
    case missingKey(key: String, dictionary: [String: Value])
    case typeMismatch(expectedType: Any.Type, value: Value)
    case invalidData(data: Any)
}

public extension _ArrayProtocol where Iterator.Element == Value {
    func valueAt(_ index: Int) throws -> Value {
        guard index < count else { throw DecodingError.outOfBounds(index: index, array: Array(self)) }
        
        return self[index]
    }
    
    func maybeValueAt(_ index: Int, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        guard index < count else {
            if throwOnMissing { throw DecodingError.outOfBounds(index: index, array: Array(self)) }
            else { return nil }
        }
        
        let value = self[index]
        
        if nilOnNull && value == .null { return nil }
        else { return value }
    }
}

public extension Collection where Iterator.Element == (key: String, value: Value) {
    func valueFor(_ key: String) throws -> Value {
        let `self` = self as! [String: Value]
        
        guard let value = self[key] else { throw DecodingError.missingKey(key: key, dictionary: self) }
        
        return value
    }
    
    func maybeValueFor(_ key: String, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        let `self` = self as! [String: Value]
        
        guard let value = self[key] else {
            if throwOnMissing { throw DecodingError.missingKey(key: key, dictionary: self) }
            else { return nil }
        }
        
        if nilOnNull && value == .null { return nil }
        else { return value }
    }
}

public extension Value {
    func valueAt(_ index: Int) throws -> Value {
        return try asArray().valueAt(index)
    }
    
    func maybeValueAt(_ index: Int, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        return try asArray().maybeValueAt(index, nilOnNull: nilOnNull, throwOnMissing: throwOnMissing)
    }
    
    func valueFor(_ key: String) throws -> Value {
        return try asDictionary().valueFor(key)
    }
    
    func maybeValueFor(_ key: String, nilOnNull: Bool = true, throwOnMissing: Bool = true) throws -> Value? {
        return try asDictionary().maybeValueFor(key, nilOnNull: nilOnNull, throwOnMissing: throwOnMissing)
    }
}

public extension Value {
    func asBool() throws -> Bool {
        switch self {
        case let .boolean(bool): return bool
        case let .string(string) where string == "true" || string == "false": return string == "true" ? true : false
        case let .double(double) where double == 1 || double == 0: return double == 1 ? true : false
        case let .integer(int) where int == 1 || int == 0: return int == 1 ? true : false
        case let .other(other as Bool): return other
        default: throw DecodingError.typeMismatch(expectedType: Bool.self, value: self)
        }
    }
    
    func asInt() throws -> Int {
        switch self {
        case let .integer(int): return int
        case let .double(double) where double < Double(Int.max): return Int(double)
        case let .other(other as Int): return other
        case let .string(string):
            if let int = Int(string) { return int }
            else { fallthrough }
        default: throw DecodingError.typeMismatch(expectedType: Int.self, value: self)
        }
    }
    
    func asDouble() throws -> Double {
        switch self {
        case let .double(double): return double
        case let .integer(int): return Double(int)
        case let .other(other as Double): return other
        case let .string(string):
            if let double = Double(string) { return double }
            else { fallthrough }
        default: throw DecodingError.typeMismatch(expectedType: Double.self, value: self)
        }
    }
    
    func asString() throws -> String {
        switch self {
        case let .string(string): return string
        case let .boolean(bool): return "\(bool)"
        case let .integer(int): return "\(int)"
        case let .double(double): return "\(double)"
        case let .other(other as String): return other
        default: throw DecodingError.typeMismatch(expectedType: String.self, value: self)
        }
    }

    func asArray() throws -> [Value] {
        switch self {
        case let .array(array): return array
        case let .other(other as [Value]): return other
        default: throw DecodingError.typeMismatch(expectedType: [Value].self, value: self)
        }
    }
    
    func asDictionary() throws -> [String: Value] {
        switch self {
        case let .dictionary(dictionary): return dictionary
        case let .other(other as [String: Value]): return other
        default: throw DecodingError.typeMismatch(expectedType: [String: Value].self, value: self)
        }
    }
    
    func asOther() throws -> Any {
        if case let .other(other) = self { return other }
        else { throw DecodingError.typeMismatch(expectedType: Any.self, value: self) }
    }
    
    func asOther<T>(_ type: T.Type = T.self) throws -> T {
        if case let .other(other) = self, let value = other as? T { return value }
        else { throw DecodingError.typeMismatch(expectedType: T.self, value: self) }
    }
}

public extension Value {
    func asFloat() throws -> Float {
        switch self {
        case let .integer(int): return Float(int)
        case let .double(double) /*where double < Double(Float.max)*/: return Float(double)
        case let .other(other as Float): return other
        case let .string(string):
            if let float = Float(string) { return float }
            else { fallthrough }
        default: throw DecodingError.typeMismatch(expectedType: Float.self, value: self)
        }
    }
    
    func asInt64() throws -> Int64 {
        switch self {
        case let .integer(int): return Int64(int)
        case let .double(double) where double < Double(Int64.max): return Int64(double)
        case let .other(other as Int64): return other
        case let .string(string):
            if let int64 = Int64(string) { return int64 }
            else { fallthrough }
        default: throw DecodingError.typeMismatch(expectedType: Int64.self, value: self)
        }
    }

    func asUInt() throws -> UInt {
        switch self {
        case let .integer(int) where int >= 0: return UInt(int)
        case let .double(double) where double >= 0 && double < Double(UInt.max): return UInt(double)
        case let .other(other as UInt): return other
        case let .string(string):
            if let uint = UInt(string) { return uint }
            else { fallthrough }
        default: throw DecodingError.typeMismatch(expectedType: UInt.self, value: self)
        }
    }

    func asUInt64() throws -> UInt64 {
        switch self {
        case let .integer(int) where int >= 0: return UInt64(int)
        case let .double(double) where double >= 0 && double < Double(UInt64.max): return UInt64(double)
        case let .other(other as UInt64): return other
        case let .string(string):
            if let uint64 = UInt64(string) { return uint64 }
            else { fallthrough }
        default: throw DecodingError.typeMismatch(expectedType: UInt64.self, value: self)
        }
    }
    
    func asCharacter() throws -> Character {
        if case let .string(string) = self, let character = string.characters.first, string.characters.count == 1 {
            return character
        } else if case let .other(other) = self, other is Character {
            return other as! Character
        } else { throw DecodingError.typeMismatch(expectedType: Character.self, value: self) }
    }
}
