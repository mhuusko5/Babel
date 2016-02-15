public enum Value {
    case Null
    case Boolean(Bool)
    case Integer(Int)
    case Double(Swift.Double)
    case String(Swift.String)
    case Array([Value])
    case Dictionary([Swift.String: Value])
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
    
    var nativeValue: Any? {
        switch self {
        case .Null: return nil
        case let .Boolean(bool): return bool
        case let .Integer(int): return int
        case let .Double(double): return double
        case let .String(string): return string
        case let .Array(array): return array.map { $0.nativeValue }
        case let .Dictionary(dictionary):
            var nativeDictionary: [Swift.String: Any?] = [:]
            
            for (key, value) in dictionary {
                nativeDictionary[key] = value.nativeValue
            }
            
            return nativeDictionary
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
        var dictionary = [StringLiteralType: Value](minimumCapacity: elements.count)

        for (key, value) in elements { dictionary[key] = value }
        
        self = .Dictionary(dictionary)
    }
}