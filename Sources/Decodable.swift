public indirect enum DecodableError: Error {
    case nested(Decodable.Type, DecodableError)
    case immediate(Decodable.Type, DecodingError)
}

public protocol Decodable {
    static func _decode(_ value: Value) throws -> Self
}

public extension Decodable {
    static func decode(_ value: Value) throws -> Self {
        do {
            if let value = value.nativeValue as? Self {
                return value
            } else {
                return try _decode(value)
            }
        } catch let error {
            switch error {
            case let error as DecodableError: throw DecodableError.nested(self, error)
            case let error as DecodingError: throw DecodableError.immediate(self, error)
            default: throw error
            }
        }
    }
    
    static func decode(JSON: String) throws -> Self {
        return try decode(Value(JSON: JSON))
    }
    
    static func decode(native value: Any?) throws -> Self {
        return try decode(Value(native: value))
    }
}

public extension Array where Element == Value {
    func decode<T: Decodable>(type: T.Type = T.self, ignoreFailures: Bool = false) throws -> [T] {
        var array = [T]()
        
        for value in self {
            do {
                try array.append(T.decode(value))
            } catch let error {
                if !ignoreFailures { throw error }
            }
        }
    
        return array
    }
}

public extension Dictionary where Key == String, Value == Babel.Value {
    func decode<K: Decodable, V: Decodable>(
        keyType: K.Type = K.self,
        valueType: V.Type = V.self,
        ignoreFailures: Bool = false
    ) throws -> [K: V] {

        var dictionary = [K: V]()
        
        for (key, value) in self {
            do {
                if let key = key as? K {
                    dictionary[key] = try V.decode(value)
                } else {
                    try dictionary[K.decode(.string(key))] = V.decode(value)
                }
            } catch let error {
                if !ignoreFailures { throw error }
            }
        }
        
        return dictionary
    }
}

public extension Value {
    func decode<T: Decodable>(type: T.Type = T.self) throws -> T {
        return try T.decode(self)
    }
    
    func decode<T: Decodable>(type: T.Type = T.self, ignoreFailure: Bool = false) throws -> T? {
        do {
            return try T.decode(self)
        } catch let error {
            if ignoreFailure { return nil }
            else { throw error }
        }
    }
    
    func decode<T: Decodable>(type: T.Type = T.self, ignoreFailures: Bool = false) throws -> [T] {
        return try asArray().decode(ignoreFailures: ignoreFailures)
    }
    
    func decode<K: Decodable, V: Decodable>(
        keyType: K.Type = K.self,
        valueType: V.Type = V.self,
        ignoreFailures: Bool = false
    ) throws -> [K: V] {

        return try asDictionary().decode(ignoreFailures: ignoreFailures)
    }
}

extension Bool: Decodable {
    public static func _decode(_ value: Value) throws -> Bool { return try value.asBool() }
}

extension Int: Decodable {
    public static func _decode(_ value: Value) throws -> Int { return try value.asInt() }
}

extension Double: Decodable {
    public static func _decode(_ value: Value) throws -> Double { return try value.asDouble() }
}

extension String: Decodable {
    public static func _decode(_ value: Value) throws -> String { return try value.asString() }
}

extension Float: Decodable {
    public static func _decode(_ value: Value) throws -> Float { return try value.asFloat() }
}

extension Int64: Decodable {
    public static func _decode(_ value: Value) throws -> Int64 { return try value.asInt64() }
}

extension UInt: Decodable {
    public static func _decode(_ value: Value) throws -> UInt { return try value.asUInt() }
}

extension UInt64: Decodable {
    public static func _decode(_ value: Value) throws -> UInt64 { return try value.asUInt64() }
}

extension Character: Decodable {
    public static func _decode(_ value: Value) throws -> Character { return try value.asCharacter() }
}
