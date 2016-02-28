#if os(Linux)
import func Glibc.pow
import func Glibc.floor
#else
import func Darwin.pow
import func Darwin.floor
#endif

public extension Value {
    init(JSON: Swift.String) throws {
        self = try JSONParser(JSON.utf8).parse()
    }
    
    init(JSON: [UInt8]) throws {
        self = try JSONParser(JSON).parse()
    }
    
    init(JSON: [Int8]) throws {
        self = try JSONParser(JSON.map { UInt8(bitPattern: $0) }).parse()
    }
}

class JSONParser<ByteSequence: CollectionType where ByteSequence.Generator.Element == UInt8> {
    typealias Source = ByteSequence
    private typealias Char = Source.Generator.Element
    
    private let source: Source
    private var cur: Source.Index
    private let end: Source.Index
    
    private var lineNumber = 1
    private var columnNumber = 1
    
    init(_ source: Source) {
        self.source = source
        self.cur = source.startIndex
        self.end = source.endIndex
    }
    
    func parse() throws -> Value {
        let JSON = try parseValue()
        
        skipWhitespaces()
        
        if (cur == end) {
            return JSON
        } else {
            throw ParsingError.ExtraToken(
                reason: "Extra tokens found.",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
    }
    
    private func parseValue() throws -> Value {
        skipWhitespaces()
        
        if cur == end {
            throw ParsingError.InsufficientToken(
                reason: "Unexpected end of tokens.",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
        
        switch currentChar {
        case Char(ascii: "n"): return try parseSymbol("null", .Null)
        case Char(ascii: "t"): return try parseSymbol("true", .Boolean(true))
        case Char(ascii: "f"): return try parseSymbol("false", .Boolean(false))
        case Char(ascii: "-"), Char(ascii: "0") ... Char(ascii: "9"): return try parseNumber()
        case Char(ascii: "\""): return try parseString()
        case Char(ascii: "{"): return try parseDictionary()
        case Char(ascii: "["): return try parseArray()
        case let c:
            throw ParsingError.UnexpectedToken(
                reason: "Unexpected token: \(c).",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
    }
    
    private var currentChar: Char {
        return source[cur]
    }
    
    private var nextChar: Char {
        return source[cur.successor()]
    }
    
    private var currentSymbol: Character {
        return Character(UnicodeScalar(currentChar))
    }
    
    private func parseSymbol(target: StaticString, @autoclosure _ iftrue: Void -> Value) throws -> Value {
        if expect(target) {
            return iftrue()
        } else {
            throw ParsingError.UnexpectedToken(
                reason: "Expected \"\(target)\" but \(currentSymbol).",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
    }
    
    private func parseString() throws -> Value {
        assert(currentChar == Char(ascii: "\""), "points a double quote")
        
        advance()
        
        var buffer: [CChar] = []
        
        LOOP: while cur != end {
            switch currentChar {
            case Char(ascii: "\\"):
                advance()
                
                if (cur == end) {
                    throw ParsingError.InvalidString(
                        reason: "Unexpected end of a string literal.",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }
                
                if let c = parseEscapedChar() {
                    for u in String(c).utf8 {
                        buffer.append(CChar(bitPattern: u))
                    }
                } else {
                    throw ParsingError.InvalidString(
                        reason: "Invalid escape sequence.",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }
            case Char(ascii: "\""): break LOOP
            default: buffer.append(CChar(bitPattern: currentChar))
            }
            
            advance()
        }
        
        if !expect("\"") {
            throw ParsingError.InvalidString(
                reason: "Missing double quote.",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
        
        buffer.append(0)
        
        let s = String.fromCString(buffer)!
        
        return .String(s)
    }
    
    private func parseEscapedChar() -> UnicodeScalar? {
        let c = UnicodeScalar(currentChar)
        
        if c == "u" {
            var length = 0
            var value: UInt32 = 0
            
            while let d = hexToDigit(nextChar) {
                advance()
                length += 1
                
                if length > 8 {
                    break
                }
                
                value = (value << 4) | d
            }
            
            if length < 2 {
                return nil
            }
            
            return UnicodeScalar(value)
        } else {
            let c = UnicodeScalar(currentChar)
            
            return unescapeMapping[c] ?? c
        }
    }
    
    private func parseNumber() throws -> Value {
        let sign = expect("-") ? -1.0 : 1.0
        var integer: Int64 = 0
        
        switch currentChar {
        case Char(ascii: "0"): advance()
        case Char(ascii: "1") ... Char(ascii: "9"):
            while cur != end {
                if let value = digitToInt(currentChar) {
                    integer = (integer * 10) + Int64(value)
                } else {
                    break
                }
                
                advance()
            }
        default:
            throw ParsingError.InvalidString(
                reason: "Missing double quote.",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
        
        if integer != Int64(Double(integer)) {
            throw ParsingError.InvalidNumber(
                reason: "Too large number.",
                lineNumber: lineNumber,
                columnNumber: columnNumber
            )
        }
        
        var fraction: Double = 0.0
        
        if expect(".") {
            var factor = 0.1
            var fractionLength = 0
            
            while cur != end {
                if let value = digitToInt(currentChar) {
                    fraction += (Double(value) * factor)
                    factor /= 10
                    fractionLength += 1
                } else {
                    break
                }
                
                advance()
            }
            
            if fractionLength == 0 {
                throw ParsingError.InvalidNumber(
                    reason: "Insufficient fraction part in number.",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
        }
        
        var exponent: Int64 = 0
        
        if expect("e") || expect("E") {
            var expSign: Int64 = 1
            
            if expect("-") {
                expSign = -1
            } else if expect("+") { }
            
            exponent = 0
            var exponentLength = 0
            
            while cur != end {
                if let value = digitToInt(currentChar) {
                    exponent = (exponent * 10) + Int64(value)
                    exponentLength += 1
                } else {
                    break
                }
                
                advance()
            }
            
            if exponentLength == 0 {
                throw ParsingError.InvalidNumber(
                    reason: "Insufficient exponent part in number.",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
            
            exponent *= expSign
        }
        
        let double = sign * (Double(integer) + fraction) * pow(10, Double(exponent))
        
        if double < Double(Int.max) && floor(double) == double {
            return .Integer(Int(double))
        } else {
            return .Double(double)
        }
    }
    
    private func parseDictionary() throws -> Value {
        assert(currentChar == Char(ascii: "{"), "points \"{\"")
        
        advance()
        skipWhitespaces()
        
        var object = [String: Value]()
        
        LOOP: while cur != end && !expect("}") {
            let keyValue = try parseValue()
            
            switch keyValue {
            case .String(let key):
                skipWhitespaces()
                
                if !expect(":") {
                    throw ParsingError.UnexpectedToken(
                        reason: "Missing colon (:).",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }
                
                skipWhitespaces()
                let value = try parseValue()
                object[key] = value
                skipWhitespaces()
                
                if expect(",") {
                    break
                } else if expect("}") {
                    break LOOP
                } else {
                    throw ParsingError.UnexpectedToken(
                        reason: "Missing comma (,).",
                        lineNumber: lineNumber,
                        columnNumber: columnNumber
                    )
                }
            default:
                throw ParsingError.NonStringKey(
                    reason: "Unexpected value for object key.",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
        }
        
        return .Dictionary(object)
    }
    
    private func parseArray() throws -> Value {
        assert(currentChar == Char(ascii: "["), "points \"[\"")
        
        advance()
        skipWhitespaces()
        
        var array = [Value]()
        
        LOOP: while cur != end && !expect("]") {
            let JSON = try parseValue()
            skipWhitespaces()
            array.append(JSON)
            
            if expect(",") {
                continue
            } else if expect("]") {
                break LOOP
            } else {
                throw ParsingError.UnexpectedToken(
                    reason: "Missing comma (,) (token: \(currentSymbol)).",
                    lineNumber: lineNumber,
                    columnNumber: columnNumber
                )
            }
        }
        
        return .Array(array)
    }
    
    private func expect(target: StaticString) -> Bool {
        if cur == end {
            return false
        }
        
        if !isIdentifier(target.utf8Start.memory) {
            if target.utf8Start.memory == currentChar {
                advance()
                
                return true
            } else {
                return false
            }
        }
        
        let start = cur
        let l = lineNumber
        let c = columnNumber
        
        var p = target.utf8Start
        let endp = p.advancedBy(Int(target.byteSize))
        
        while p != endp {
            if p.memory != currentChar {
                cur = start
                lineNumber = l
                columnNumber = c
                
                return false
            }
            
            p += 1
            
            advance()
        }
        
        return true
    }
    
    private func isIdentifier(char: Char) -> Bool {
        switch char {
        case Char(ascii: "a") ... Char(ascii: "z"): return true
        default: return false
        }
    }
    
    private func advance() {
        assert(cur != end, "out of range")
        
        cur++
        
        if cur != end {
            switch currentChar {
            case Char(ascii: "\n"): lineNumber += 1; columnNumber = 1
            default: columnNumber += 1
            }
        }
    }
    
    private func skipWhitespaces() {
        while cur != end {
            switch currentChar {
            case Char(ascii: " "), Char(ascii: "\t"), Char(ascii: "\r"), Char(ascii: "\n"): break
            default: return
            }
            
            advance()
        }
    }
}

private func escapeAsJSONString(source: String) -> String {
    var s = "\""
    
    for c in source.characters {
        if let escapedSymbol = escapeMapping[c] {
            s.appendContentsOf(escapedSymbol)
        } else {
            s.append(c)
        }
    }
    
    s.appendContentsOf("\"")
    
    return s
}

private let unescapeMapping: [UnicodeScalar: UnicodeScalar] = [
    "t": "\t",
    "r": "\r",
    "n": "\n"
]

private let escapeMapping: [Character: String] = [
    "\r": "\\r",
    "\n": "\\n",
    "\t": "\\t",
    "\\": "\\\\",
    "\"": "\\\"",
    
    "\u{2028}": "\\u2028",
    "\u{2029}": "\\u2029",
    
    "\r\n": "\\r\\n"
]

private func digitToInt(byte: UInt8) -> Int? {
    return digitMapping[UnicodeScalar(byte)]
}

private func hexToDigit(byte: UInt8) -> UInt32? {
    return hexMapping[UnicodeScalar(byte)]
}

private let hexMapping: [UnicodeScalar: UInt32] = [
    "0": 0x0,
    "1": 0x1,
    "2": 0x2,
    "3": 0x3,
    "4": 0x4,
    "5": 0x5,
    "6": 0x6,
    "7": 0x7,
    "8": 0x8,
    "9": 0x9,
    "a": 0xA, "A": 0xA,
    "b": 0xB, "B": 0xB,
    "c": 0xC, "C": 0xC,
    "d": 0xD, "D": 0xD,
    "e": 0xE, "E": 0xE,
    "f": 0xF, "F": 0xF
]

private let digitMapping: [UnicodeScalar: Int] = [
    "0": 0,
    "1": 1,
    "2": 2,
    "3": 3,
    "4": 4,
    "5": 5,
    "6": 6,
    "7": 7,
    "8": 8,
    "9": 9
]