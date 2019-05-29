infix operator => : MultiplicationPrecedence
infix operator =>? : MultiplicationPrecedence
infix operator =>?? : MultiplicationPrecedence

// MARK: - Array -

public func =>(lhs: Value, rhs: Int) throws -> Value {
    return try lhs.valueAt(rhs)
}

public func =><T: Decodable>(lhs: Value, rhs: Int) throws -> T {
    return try (lhs => rhs).decode()
}

// MARK: Nil Chaining

public func =>(lhs: Value?, rhs: Int) throws -> Value? {
    return try lhs.map { try $0 => rhs }
}

public func =><T: Decodable>(lhs: Value?, rhs: Int) throws -> T? {
    return try (lhs => rhs)?.decode()
}

// MARK: - Array (Accept Null) -

public func =>?(lhs: Value, rhs: Int) throws -> Value? {
    return try lhs.maybeValueAt(rhs, throwOnMissing: true)
}

public func =>?<T: Decodable>(lhs: Value, rhs: Int) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>?(lhs: Value?, rhs: Int) throws -> Value? {
    return try lhs.flatMap { try $0 =>? rhs }
}

public func =>?<T: Decodable>(lhs: Value?, rhs: Int) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: - Array (Accept Out of Bounds or Null) -

public func =>??(lhs: Value, rhs: Int) throws -> Value? {
    return try lhs.maybeValueAt(rhs)
}

public func =>??<T: Decodable>(lhs: Value, rhs: Int) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>??(lhs: Value?, rhs: Int) throws -> Value? {
    return try lhs.flatMap { try $0 =>?? rhs }
}

public func =>??<T: Decodable>(lhs: Value?, rhs: Int) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

// MARK: - Dictionary -

public func =>(lhs: Value, rhs: String) throws -> Value {
    return try lhs.valueFor(rhs)
}

public func =><T: Decodable>(lhs: Value, rhs: String) throws -> T {
    return try (lhs => rhs).decode()
}

// MARK: Nil Chaining

public func =>(lhs: Value?, rhs: String) throws -> Value? {
    return try lhs.map { try $0 => rhs }
}

public func =><T: Decodable>(lhs: Value?, rhs: String) throws -> T? {
    return try (lhs => rhs)?.decode()
}

// MARK: - Dictionary (Accept Null) -

public func =>?(lhs: Value, rhs: String) throws -> Value? {
    return try lhs.maybeValueFor(rhs, throwOnMissing: true)
}

public func =>?<T: Decodable>(lhs: Value, rhs: String) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>?(lhs: Value?, rhs: String) throws -> Value? {
    return try lhs.flatMap { try $0 =>? rhs }
}

public func =>?<T: Decodable>(lhs: Value?, rhs: String) throws -> T? {
    return try (lhs =>? rhs)?.decode()
}

// MARK: - Dictionary (Accept Missing Key or Null) -

public func =>??(lhs: Value, rhs: String) throws -> Value? {
    return try lhs.maybeValueFor(rhs)
}

public func =>??<T: Decodable>(lhs: Value, rhs: String) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}

// MARK: Nil Chaining

public func =>??(lhs: Value?, rhs: String) throws -> Value? {
    return try lhs.flatMap { try $0 =>?? rhs }
}

public func =>??<T: Decodable>(lhs: Value?, rhs: String) throws -> T? {
    return try (lhs =>?? rhs)?.decode()
}
