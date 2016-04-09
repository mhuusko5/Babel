public enum Value {
    case Null
    case Boolean(Bool)
    case Integer(Int)
    case Double(Swift.Double)
    case String(Swift.String)
    case Array([Value])
    case Dictionary([Swift.String: Value])
    case Other(Any)
}

public extension Value {
    var isNull: Bool { return self == .Null }
    
    var isBoolean: Bool {
        if case .Boolean = self { return true } else { return false }
    }
    
    var isInteger: Bool {
        if case .Integer = self { return true } else { return false }
    }
    
    var isDouble: Bool {
        if case .Double = self { return true } else { return false }
    }
    
    var isString: Bool {
        if case .String = self { return true } else { return false }
    }
    
    var isArray: Bool {
        if case .Array = self { return true } else { return false }
    }
    
    var isDictionary: Bool {
        if case .Dictionary = self { return true } else { return false }
    }
    
    var isOther: Bool {
        if case .Other = self { return true } else { return false }
    }
}

public extension Value {
    var boolValue: Bool? {
        if case let .Boolean(bool) = self { return bool }
        else { return nil }
    }
    
    var intValue: Int? {
        if case let .Integer(int) = self { return int }
        else { return nil }
    }
    
    var doubleValue: Swift.Double? {
        if case let .Double(double) = self { return double }
        else { return nil }
    }
    
    var stringValue: Swift.String? {
        if case let .String(string) = self { return string }
        else { return nil }
    }
    
    var arrayValue: [Value]? {
        if case let .Array(array) = self { return array }
        else { return nil }
    }
    
    var dictionaryValue: [Swift.String: Value]? {
        if case let .Dictionary(dictionary) = self { return dictionary }
        else { return nil }
    }
    
    var otherValue: Any? {
        if case let .Other(other) = self { return other }
        else { return nil }
    }
    
    var nativeValue: Any? {
        switch self {
        case .Null: return nil
        case let .Boolean(bool): return bool
        case let .Integer(int): return int
        case let .Double(double): return double
        case let .String(string): return string
        case let .Array(array): return array.map { $0.nativeValue }
        case let .Dictionary(dictionary): return dictionary.dictMap { ($0, $1.nativeValue) }
        case let .Other(other): return other
        }
    }
}

public extension Value {
    subscript(index: Int) -> Value? {
        if case let .Array(array) = self where index < array.count {
            return array[index]
        } else { return nil }
    }
    
    subscript(key: Swift.String) -> Value? {
        if case let .Dictionary(dictionary) = self {
            return dictionary[key]
        } else { return nil }
    }
}

extension Value: Equatable {}

public func ==(lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.Null, .Null): return true
    case let (.Boolean(lhs), .Boolean(rhs)): return lhs == rhs
    case let (.Integer(lhs), .Integer(rhs)): return lhs == rhs
    case let (.Double(lhs), .Double(rhs)): return lhs == rhs
    case let (.String(lhs), .String(rhs)): return lhs == rhs
    case let (.Array(lhs), .Array(rhs)): return lhs == rhs
    case let (.Dictionary(lhs), .Dictionary(rhs)): return lhs == rhs
    default: return false
    }
}

public extension Value {
    init(_ bool: Bool) { self = .Boolean(bool) }
    
    init(_ int: Int) { self = .Integer(int) }
    
    init(_ double: Swift.Double) { self = .Double(double) }
    
    init(_ string: Swift.String) { self = .String(string) }
    
    init(_ array: [Value]) { self = .Array(array) }
    
    init(_ dictionary: [Swift.String: Value]) { self = .Dictionary(dictionary) }
    
    init(other: Any) { self = .Other(other) }
}

public extension Value {
    init(native: Any?) {
        switch native {
        case nil: self = .Null
        case let bool as Bool: self = .Boolean(bool)
        case let int as Int: self = .Integer(int)
        case let int64 as Int64:
            if int64 < Int64(Int.max) { self = .Integer(Int(int64)) }
            else { self = .Double(Swift.Double(int64)) }
        case let double as Swift.Double: self = .Double(double)
        case let float as Float: self = .Double(Swift.Double(float))
        case let string as Swift.String: self = .String(string)
        default:
            if let dictionary = castDictionary(native) {
                self = .Dictionary(dictionary.dictMap { ($0, Value(native: $1)) })
            } else if let array = castArray(native) {
                self = .Array(array.map { Value(native: $0) })
            } else {
                self = .Other(native)
            }
        }
    }
}

extension Value: NilLiteralConvertible {
    public init(nilLiteral value: Void) { self = .Null }
}

extension Value: BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) { self = .Boolean(value) }
}

extension Value: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) { self = .Integer(value) }
}

extension Value: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) { self = .Double(Swift.Double(value)) }
}

extension Value: StringLiteralConvertible {
    public typealias UnicodeScalarLiteralType = Swift.String

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) { self = .String(value) }
    
    public typealias ExtendedGraphemeClusterLiteralType = Swift.String
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) { self = .String(value) }
    
    public init(stringLiteral value: StringLiteralType) { self = .String(value) }
}

extension Value: ArrayLiteralConvertible {
    public init(arrayLiteral elements: Value...) { self = .Array(elements) }
}

extension Value: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (StringLiteralType, Value)...) {
        self = .Dictionary([StringLiteralType: Value](elements))
    }
}

// MARK: - Helpers -

private extension Dictionary {
    init(_ elements: [Element]) {
        self.init(minimumCapacity: elements.count)
        
        for (key, value) in elements { self[key] = value }
    }
    
    func dictMap<K, V>(@noescape transform: (Key, Value) throws -> (K, V)) rethrows -> [K: V] {
        return try [K: V](map(transform))
    }
}

private func castDictionary(any: Any) -> [String: Any]? {
    let mirror = Mirror(reflecting: any)
    
    guard let displayStyle = mirror.displayStyle where displayStyle == .Dictionary else {
        return nil
    }
    
    var dictionary = [String: Any]()
    
    for property in Array(mirror.children) {
        let pair = Array(Mirror(reflecting: property.value).children)
        
        if let key = pair[0].value as? String {
            dictionary[key] = pair[1].value
        } else {
            return nil
        }
    }
    
    return dictionary
}

private func castArray(any: Any) -> [Any]? {
    let mirror = Mirror(reflecting: any)
    
    if let displayStyle = mirror.displayStyle where displayStyle == .Collection || displayStyle == .Set {
        return Array(mirror.children).map { $0.value }
    }
    
    return nil
}