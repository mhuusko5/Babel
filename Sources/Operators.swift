infix operator => { associativity left precedence 150 }
infix operator =>? { associativity left precedence 150 }
infix operator =>?? { associativity left precedence 150 }

// MARK: - Array -

public func =>(lhs: Value, rhs: Int) throws -> Value {
    return try lhs.valueAt(rhs)
}

public func =><T: Decodable>(lhs: Value, rhs: Int) throws -> T {
    return try (lhs => rhs).decode()
}

public func =><T: Decodable>(lhs: Value, rhs: Int) throws -> [T] {
    return try (lhs => rhs).decode()
}

public func =><K: Decodable, V: Decodable>(lhs: Value, rhs: Int) throws -> [K: V] {
    return try (lhs => rhs).decode()
}

// MARK: Nil Chaining

public func =>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> Value? {
    return try lhs.map { try $0 => rhs() }
}

public func =><T: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> T? {
    return try (lhs => rhs)?.decode()
}

public func =><T: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> [T]? {
    return try (lhs => rhs)?.decode()
}

public func =><K: Decodable, V: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> [K: V]? {
    return try (lhs => rhs)?.decode()
}

// MARK: - Array (Accept Null) -

public func =>?(lhs: Value, rhs: Int) throws -> Value? {
    return try lhs.maybeValueAt(rhs)
}

public func =>?<T: Decodable>(lhs: Value, rhs: Int) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<T: Decodable>(lhs: Value, rhs: Int) throws -> [T]? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<K: Decodable, V: Decodable>(lhs: Value, rhs: Int) throws -> [K: V]? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>?(lhs: Value?, @autoclosure rhs: () -> Int) throws -> Value? {
    return try lhs.flatMap { try $0 =>? rhs() }
}

public func =>?<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> [T]? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<K: Decodable, V: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> [K: V]? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: - Array (Accept Out of Bounds or Null) -

public func =>??(lhs: Value, rhs: Int) throws -> Value? {
    return try lhs.maybeValueAt(rhs, throwOnMissing: false)
}

public func =>??<T: Decodable>(lhs: Value, rhs: Int) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<T: Decodable>(lhs: Value, rhs: Int) throws -> [T]? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<K: Decodable, V: Decodable>(lhs: Value, rhs: Int) throws -> [K: V]? {
    return try (lhs =>?? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>??(lhs: Value?, @autoclosure rhs: () -> Int) throws -> Value? {
    return try lhs.flatMap { try $0 =>?? rhs() }
}

public func =>??<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> [T]? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<K: Decodable, V: Decodable>(lhs: Value?, @autoclosure rhs: () -> Int) throws -> [K: V]? {
    return try (lhs =>?? rhs)?.decode()
}

// MARK: - Dictionary -

public func =>(lhs: Value, rhs: String) throws -> Value {
    return try lhs.valueFor(rhs)
}

public func =><T: Decodable>(lhs: Value, rhs: String) throws -> T {
    return try (lhs => rhs).decode()
}

public func =><T: Decodable>(lhs: Value, rhs: String) throws -> [T] {
    return try (lhs => rhs).decode()
}

public func =><K: Decodable, V: Decodable>(lhs: Value, rhs: String) throws -> [K: V] {
    return try (lhs => rhs).decode()
}

// MARK: Nil Chaining

public func =>(lhs: Value?, @autoclosure rhs: () -> String) throws -> Value? {
    return try lhs.map { try $0 => rhs() }
}

public func =><T: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> T? {
    return try (lhs => rhs)?.decode()
}

public func =><T: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> [T]? {
    return try (lhs => rhs)?.decode()
}

public func =><K: Decodable, V: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> [K: V]? {
    return try (lhs => rhs)?.decode()
}

// MARK: - Dictionary (Accept Null) -

public func =>?(lhs: Value, rhs: String) throws -> Value? {
    return try lhs.maybeValueFor(rhs)
}

public func =>?<T: Decodable>(lhs: Value, rhs: String) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<T: Decodable>(lhs: Value, rhs: String) throws -> [T]? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<K: Decodable, V: Decodable>(lhs: Value, rhs: String) throws -> [K: V]? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>?(lhs: Value?, @autoclosure rhs: () -> String) throws -> Value? {
    return try lhs.flatMap { try $0 =>? rhs() }
}

public func =>?<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> [T]? {
    return try (lhs =>? rhs)?.decode()
}

public func =>?<K: Decodable, V: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> [K: V]? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: - Dictionary (Accept Missing Key or Null) -

public func =>??(lhs: Value, rhs: String) throws -> Value? {
    return try lhs.maybeValueFor(rhs, throwOnMissing: false)
}

public func =>??<T: Decodable>(lhs: Value, rhs: String) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<T: Decodable>(lhs: Value, rhs: String) throws -> [T]? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<K: Decodable, V: Decodable>(lhs: Value, rhs: String) throws -> [K: V]? {
    return try (lhs =>?? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>??(lhs: Value?, @autoclosure rhs: () -> String) throws -> Value? {
    return try lhs.flatMap { try $0 =>?? rhs() }
}

public func =>??<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<T: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> [T]? {
    return try (lhs =>?? rhs)?.decode()
}

public func =>??<K: Decodable, V: Decodable>(lhs: Value?, @autoclosure rhs: () -> String) throws -> [K: V]? {
    return try (lhs =>?? rhs)?.decode()
}