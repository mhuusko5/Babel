public enum Value {
    case null
    case boolean(Bool)
    case integer(Int)
    case double(Double)
    case string(String)
    case array([Value])
    case dictionary([String: Value])
    case other(Any)
}

public extension Value {
    var isNull: Bool { return self == .null }
    
    var isBoolean: Bool {
        if case .boolean = self { return true } else { return false }
    }
    
    var isInteger: Bool {
        if case .integer = self { return true } else { return false }
    }
    
    var isDouble: Bool {
        if case .double = self { return true } else { return false }
    }
    
    var isString: Bool {
        if case .string = self { return true } else { return false }
    }
    
    var isArray: Bool {
        if case .array = self { return true } else { return false }
    }
    
    var isDictionary: Bool {
        if case .dictionary = self { return true } else { return false }
    }
    
    var isOther: Bool {
        if case .other = self { return true } else { return false }
    }
}

public extension Value {
    var boolValue: Bool? {
        if case let .boolean(bool) = self { return bool }
        else { return nil }
    }
    
    var intValue: Int? {
        if case let .integer(int) = self { return int }
        else { return nil }
    }
    
    var doubleValue: Double? {
        if case let .double(double) = self { return double }
        else { return nil }
    }
    
    var stringValue: String? {
        if case let .string(string) = self { return string }
        else { return nil }
    }
    
    var arrayValue: [Value]? {
        if case let .array(array) = self { return array }
        else { return nil }
    }
    
    var dictionaryValue: [String: Value]? {
        if case let .dictionary(dictionary) = self { return dictionary }
        else { return nil }
    }
    
    var otherValue: Any? {
        if case let .other(other) = self { return other }
        else { return nil }
    }
    
    var nativeValue: Any? {
        switch self {
        case .null: return nil
        case let .boolean(bool): return bool
        case let .integer(int): return int
        case let .double(double): return double
        case let .string(string): return string
        case let .array(array): return array.map { $0.nativeValue }
        case let .dictionary(dictionary): return dictionary.dictMap { ($0, $1.nativeValue) }
        case let .other(other): return other
        }
    }
}

public extension Value {
    subscript(index: Int) -> Value? {
        if case let .array(array) = self, index < array.count {
            return array[index]
        } else { return nil }
    }
    
    subscript(key: String) -> Value? {
        if case let .dictionary(dictionary) = self {
            return dictionary[key]
        } else { return nil }
    }
}

extension Value: Equatable {}

public func ==(lhs: Value, rhs: Value) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null): return true
    case let (.boolean(lhs), .boolean(rhs)): return lhs == rhs
    case let (.integer(lhs), .integer(rhs)): return lhs == rhs
    case let (.double(lhs), .double(rhs)): return lhs == rhs
    case let (.string(lhs), .string(rhs)): return lhs == rhs
    case let (.array(lhs), .array(rhs)): return lhs == rhs
    case let (.dictionary(lhs), .dictionary(rhs)): return lhs == rhs
    default: return false
    }
}

public extension Value {
    init(_ bool: Bool) { self = .boolean(bool) }
    
    init(_ int: Int) { self = .integer(int) }
    
    init(_ double: Double) { self = .double(double) }
    
    init(_ string: String) { self = .string(string) }
    
    init(_ array: [Value]) { self = .array(array) }
    
    init(_ dictionary: [String: Value]) { self = .dictionary(dictionary) }
    
    init(other: Any) { self = .other(other) }
}

public extension Value {
    static func from(native value: Any?) -> Value {
        switch value {
        case nil: return .null
        case let bool as Bool: return .boolean(bool)
        case let int as Int: return .integer(int)
        case let int64 as Int64:
            if int64 < Int64(Int.max) { return .integer(Int(int64)) }
            else { return .double(Double(int64)) }
        case let uint as UInt:
            if uint < UInt(Int.max) { return .integer(Int(uint)) }
            else { return .double(Double(uint)) }
        case let uint64 as UInt64:
            if uint64 < UInt64(Int.max) { return .integer(Int(uint64)) }
            else { return .double(Double(uint64)) }
        case let double as Double: return .double(double)
        case let float as Float: return .double(Double(float))
        case let string as String: return .string(string)
        case let character as Character: return .string(String(character))
        default:
            if let (value, mirror) = deepUnwrap(value) {
                if let dictionary = castDictionary(mirror) {
                    return .dictionary(dictionary.dictMap { ($0, .from(native: $1)) })
                } else if let array = castArray(mirror) {
                    return .array(array.map { .from(native: $0) })
                } else {
                    return .other(value)
                }
            } else {
                return .null
            }
        }
    }

    init(native value: Any?) {
        self = .from(native: value)
    }
}

extension Value: ExpressibleByNilLiteral {
    public init(nilLiteral value: Void) { self = .null }
}

extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) { self = .boolean(value) }
}

extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) { self = .integer(value) }
}

extension Value: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) { self = .double(Double(value)) }
}

extension Value: ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = String

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) { self = .string(value) }
    
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) { self = .string(value) }
    
    public init(stringLiteral value: StringLiteralType) { self = .string(value) }
}

extension Value: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) { self = .array(elements) }
}

extension Value: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (StringLiteralType, Value)...) {
        self = .dictionary([StringLiteralType: Value](elements))
    }
}

// MARK: - Helpers -

private extension Dictionary {
    init(_ elements: [Element]) {
        self.init(minimumCapacity: elements.count)
        
        for (key, value) in elements { self[key] = value }
    }
    
    func dictMap<K, V>(_ transform: (Key, Value) throws -> (K, V)) rethrows -> [K: V] {
        return try [K: V](map(transform))
    }
}

private func deepUnwrap(_ any: Any?) -> (Any, Mirror)? {
    guard let any = any else { return nil }

    let mirror = Mirror(reflecting: any)

    if mirror.displayStyle != .optional { return (any, mirror) }

    if let child = mirror.children.first, child.label == "some" {
        return deepUnwrap(child.value)
    }

    return nil
}

private func castDictionary(_ mirror: Mirror) -> [String: Any]? {
    guard mirror.displayStyle == .dictionary else { return nil }

    let children = Array(mirror.children)

    var dictionary = [String: Any](minimumCapacity: children.count)

    for property in children {
        let pair = Array(Mirror(reflecting: property.value).children)
        
        if let key = pair[0].value as? String {
            dictionary[key] = pair[1].value
        } else if let index = pair[0].value as? Int {
            dictionary[String(index)] = pair[1].value
        } else {
            return nil
        }
    }
    
    return dictionary
}

private func castArray(_ mirror: Mirror) -> [Any]? {
    if let displayStyle = mirror.displayStyle, displayStyle == .collection || displayStyle == .set {
        return Array(mirror.children).map { $0.value }
    }
    
    return nil
}
