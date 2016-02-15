public indirect enum DecodableError: ErrorType {
    case Nested(Decodable.Type, DecodableError)
    case Immediate(Decodable.Type, DecodingError)
}

public protocol Decodable {
    static func _decode(value: Value) throws -> Self
}

public extension Decodable {
    static func decode(value: Value) throws -> Self {
        do {
            return try _decode(value)
        } catch let error {
            if let error = error as? DecodableError {
                throw DecodableError.Nested(self, error)
            } else if let error = error as? DecodingError {
                throw DecodableError.Immediate(self, error)
            } else { throw error }
        }
    }
}

public extension _ArrayType where Generator.Element == Value {
    func decode<T: Decodable>(type type: T.Type = T.self, ignoreFailures: Bool = false) throws -> [T] {
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

public extension CollectionType where Generator.Element == (String, Value) {
    func decode<K: Decodable, V: Decodable>(keyType keyType: K.Type = K.self, valueType: V.Type = V.self, ignoreFailures: Bool = false) throws -> [K: V] {
        var dictionary = [K: V]()
        
        for (key, value) in self {
            do {
                if let key = key as? K {
                    dictionary[key] = try V.decode(value)
                } else {
                    dictionary[try K.decode(.String(key))] = try V.decode(value)
                }
            } catch let error {
                if !ignoreFailures { throw error }
            }
        }
        
        return dictionary
    }
}

public extension Value {
    func decode<T: Decodable>(type type: T.Type = T.self) throws -> T {
        return try T.decode(self)
    }
    
    func decode<T: Decodable>(type type: T.Type = T.self, ignoreFailure: Bool = false) throws -> T? {
        do {
            return try T.decode(self)
        } catch let error {
            if ignoreFailure { return nil }
            else { throw error }
        }
    }
    
    func decodeArray<T: Decodable>(type type: T.Type = T.self, ignoreFailures: Bool = false) throws -> [T] {
        return try asArray().decode(ignoreFailures: ignoreFailures)
    }
    
    func decodeDictionary<K: Decodable, V: Decodable>(keyType keyType: K.Type = K.self, valueType: V.Type = V.self, ignoreFailures: Bool = false) throws -> [K: V] {
        return try asDictionary().decode(ignoreFailures: ignoreFailures)
    }
}

extension Bool: Decodable {
    public static func _decode(value: Value) throws -> Bool { return try value.asBool() }
}

extension Int: Decodable {
    public static func _decode(value: Value) throws -> Int { return try value.asInt() }
}

extension Double: Decodable {
    public static func _decode(value: Value) throws -> Double { return try value.asDouble() }
}

extension String: Decodable {
    public static func _decode(value: Value) throws -> String { return try value.asString() }
}

extension Float: Decodable {
    public static func _decode(value: Value) throws -> Float { return try value.asFloat() }
}

extension Int64: Decodable {
    public static func _decode(value: Value) throws -> Int64 { return try value.asInt64() }
}

extension Character: Decodable {
    public static func _decode(value: Value) throws -> Character { return try value.asCharacter() }
}