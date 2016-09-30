public extension Value {
    init(JSON: String) throws {
        do {
            self = try JSONParser.parse(string: JSON)
        } catch _ {
            throw DecodingError.invalidData(data: JSON)
        }
    }
    
    init(JSON: String.UnicodeScalarView) throws {
        do {
            self = try JSONParser.parse(scalars: JSON)
        } catch _ {
            throw DecodingError.invalidData(data: JSON)
        }
    }
}

private class JSONParser {
    enum Error: Swift.Error {
        case unknown
        case emptyInput
        case unexpectedCharacter(lineNumber: UInt, characterNumber: UInt)
        case unterminatedString
        case invalidUnicode
        case unexpectedKeyword(lineNumber: UInt, characterNumber: UInt)
        case invalidNumber(lineNumber: UInt, characterNumber: UInt)
        case endOfFile
    }
    
    class func parse(scalars: String.UnicodeScalarView) throws -> Value {
        let parser = JSONParser(scalars: scalars)
        return try parser.parse()
    }

    class func parse(string: String) throws -> Value {
        let parser = JSONParser(scalars: string.unicodeScalars)
        return try parser.parse()
    }

    init(scalars: String.UnicodeScalarView) {
        generator = scalars.makeIterator()
        self.data = scalars
    }

    func parse() throws -> Value {
        do {
            try nextScalar()
            let value = try nextValue()
            do {
                try nextScalar()
                let v = scalar.value
                if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                    // Skip to EOF or the next token
                    try skipToNextToken()
                    // If we get this far some token was found ...
                    throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                } else {
                    // There's some weird character at the end of the file...
                    throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                }
            } catch Error.endOfFile {
                return value
            }
        } catch Error.endOfFile {
            throw Error.emptyInput
        }
    }

    var generator: String.UnicodeScalarView.Iterator
    let data: String.UnicodeScalarView
    var scalar: UnicodeScalar!
    var lineNumber: UInt = 0
    var charNumber: UInt = 0

    var crlfHack = false

    func nextScalar() throws {
        if let sc = generator.next() {
            scalar = sc
            charNumber = charNumber + 1
            if crlfHack == true && sc != lineFeed {
                crlfHack = false
            }
        } else {
            throw Error.endOfFile
        }
    }

    func skipToNextToken() throws {
        var v = scalar.value
        if v != 0x0009 && v != 0x000A && v != 0x000D && v != 0x0020 {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }

        while v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
            if scalar == carriageReturn || scalar == lineFeed {
                if crlfHack == true && scalar == lineFeed {
                    crlfHack = false
                    charNumber = 0
                } else {
                    if (scalar == carriageReturn) {
                        crlfHack = true
                    }
                    lineNumber = lineNumber + 1
                    charNumber = 0
                }
            }
            try nextScalar()
            v = scalar.value
        }
    }

    func nextScalars(count: UInt) throws -> [UnicodeScalar] {
        var values = [UnicodeScalar]()
        values.reserveCapacity(Int(count))
        for _ in 0..<count {
            try nextScalar()
            values.append(scalar)
        }
        return values
    }

    func nextValue() throws -> Value {
        let v = scalar.value
        if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
            try skipToNextToken()
        }
        switch scalar {
        case leftCurlyBracket:
            return try nextObject()
        case leftSquareBracket:
            return try nextArray()
        case quotationMark:
            return try nextString()
        case trueToken[0], falseToken[0]:
            return try nextBool()
        case nullToken[0]:
            return try nextNull()
        case "0".unicodeScalars.first!..."9".unicodeScalars.first!,negativeScalar,decimalScalar:
            return try nextNumber()
        default:
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
    }

    func nextObject() throws -> Value {
        if scalar != leftCurlyBracket {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        var dictBuilder = [String: Value]()
        try nextScalar()
        if scalar == rightCurlyBracket {
            // Empty object
            return Value.dictionary(dictBuilder)
        }
        outerLoop: repeat {
            var v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            let string = try nextString()
            try nextScalar() // Skip the quotation character
            v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            if scalar != colon {
                throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
            try nextScalar() // Skip the ':'
            let value = try nextValue()
            switch value {
            // Skip the closing character for all values except number, which doesn't have one
            case .integer, .double:
                break
            default:
                try nextScalar()
            }
            v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            guard case .string(let key) = string else { throw Error.unknown }
            //let key = string.string! // We're pretty confident it's a string since we called nextString() above
            dictBuilder[key] = value
            switch scalar {
            case rightCurlyBracket:
                break outerLoop
            case comma:
                try nextScalar()
            default:
                throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }

        } while true
        return Value.dictionary(dictBuilder)
    }

    func nextArray() throws -> Value {
        if scalar != leftSquareBracket {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        var arrBuilder = [Value]()
        try nextScalar()
        let v = scalar.value
        if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
            try skipToNextToken()
        }
        if scalar == rightSquareBracket {
            // Empty array
            return Value.array(arrBuilder)
        }
        outerLoop: repeat {
            let value = try nextValue()
            arrBuilder.append(value)
            switch value {
            // Skip the closing character for all values except number, which doesn't have one
            case .integer, .double:
                break
            default:
                try nextScalar()
            }
            let v = scalar.value
            if v == 0x0009 || v == 0x000A || v == 0x000D || v == 0x0020 {
                try skipToNextToken()
            }
            switch scalar {
            case rightSquareBracket:
                break outerLoop
            case comma:
                try nextScalar()
            default:
                throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
        } while true

        return Value.array(arrBuilder)
    }

    func nextString() throws -> Value {
        if scalar != quotationMark {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        try nextScalar() // Skip pas the quotation character
        var strBuilder = ""
        var escaping = false
        outerLoop: repeat {
            // First we should deal with the escape character and the terminating quote
            switch scalar {
            case reverseSolidus:
                // Escape character
                if escaping {
                    // Escaping the escape char
                    strBuilder.unicodeScalars.append(reverseSolidus)
                }
                escaping = !escaping
                try nextScalar()
            case quotationMark:
                if escaping {
                    strBuilder.unicodeScalars.append(quotationMark)
                    escaping = false
                    try nextScalar()
                } else {
                    break outerLoop
                }
            default:
                // Now the rest
                if escaping {
                    // Handle all the different escape characters
                    if let s = escapeMap[scalar] {
                        strBuilder.unicodeScalars.append(s)
                        try nextScalar()
                    } else if scalar == "u".unicodeScalars.first! {
                        let escapedUnicodeValue = try nextUnicodeEscape()
                        guard let escapedUnicodeScalar = UnicodeScalar(escapedUnicodeValue) else {
                            throw Error.invalidUnicode
                        }
                        strBuilder.unicodeScalars.append(escapedUnicodeScalar)
                        try nextScalar()
                    }
                    escaping = false
                } else {
                    // Simple append
                    strBuilder.append(String(scalar))
                    try nextScalar()
                }
            }
        } while true
        return Value.string(strBuilder)
    }

    func nextUnicodeEscape() throws -> UInt32 {
        if scalar != "u".unicodeScalars.first! {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        var readScalar = UInt32(0)
        for _ in 0...3 {
            readScalar = readScalar * 16
            try nextScalar()
            if ("0".unicodeScalars.first!..."9".unicodeScalars.first!).contains(scalar) {
                readScalar = readScalar + UInt32(scalar.value - "0".unicodeScalars.first!.value)
            } else if ("a".unicodeScalars.first!..."f".unicodeScalars.first!).contains(scalar) {
                let aScalarVal = "a".unicodeScalars.first!.value
                let hexVal = scalar.value - aScalarVal
                let hexScalarVal = hexVal + 10
                readScalar = readScalar + hexScalarVal
            } else if ("A".unicodeScalars.first!..."F".unicodeScalars.first!).contains(scalar) {
                let aScalarVal = "A".unicodeScalars.first!.value
                let hexVal = scalar.value - aScalarVal
                let hexScalarVal = hexVal + 10
                readScalar = readScalar + hexScalarVal
            } else {
                throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
            }
        }
        if readScalar >= 0xD800 && readScalar <= 0xDBFF {
            // UTF-16 surrogate pair
            // The next character MUST be the other half of the surrogate pair
            // Otherwise it's a unicode error
            do {
                try nextScalar()
                if scalar != reverseSolidus {
                    throw Error.invalidUnicode
                }
                try nextScalar()
                let secondScalar = try nextUnicodeEscape()
                if secondScalar < 0xDC00 || secondScalar > 0xDFFF {
                    throw Error.invalidUnicode
                }
                let actualScalar = ((readScalar - 0xD800) * 0x400) + ((secondScalar - 0xDC00) + 0x10000)
                return actualScalar
            } catch Error.unexpectedCharacter {
                throw Error.invalidUnicode
            }
        }
        return readScalar
    }

    func nextNumber() throws -> Value {
        var isNegative = false
        var hasDecimal = false
        var hasDigits = false
        var hasExponent = false
        var positiveExponent = false
        var exponent = 0
        var integer: UInt64 = 0
        var decimal: Int64 = 0
        var divisor: Double = 10
        let lineNumAtStart = lineNumber
        let charNumAtStart = charNumber

        do {
            outerLoop: repeat {
                switch scalar {
                case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                    hasDigits = true
                    if hasDecimal {
                        decimal *= 10
                        decimal += Int64(scalar.value - zeroScalar.value)
                        divisor *= 10
                    } else {
                        integer *= 10
                        integer += UInt64(scalar.value - zeroScalar.value)
                    }
                    try nextScalar()
                case negativeScalar:
                    if hasDigits || hasDecimal || hasDigits || isNegative {
                        throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        isNegative = true
                    }
                    try nextScalar()
                case decimalScalar:
                    if hasDecimal {
                        throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        hasDecimal = true
                    }
                    try nextScalar()
                case "e".unicodeScalars.first!,"E".unicodeScalars.first!:
                    if hasExponent {
                        throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    } else {
                        hasExponent = true
                    }
                    try nextScalar()
                    switch scalar {
                    case "0".unicodeScalars.first!..."9".unicodeScalars.first!:
                        positiveExponent = true
                    case plusScalar:
                        positiveExponent = true
                        try nextScalar()
                    case negativeScalar:
                        positiveExponent = false
                        try nextScalar()
                    default:
                        throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
                    }
                    exponentLoop: repeat {
                        if scalar.value >= zeroScalar.value && scalar.value <= "9".unicodeScalars.first!.value {
                            exponent *= 10
                            exponent += Int(scalar.value - zeroScalar.value)
                            try nextScalar()
                        } else {
                            break exponentLoop
                        }
                    } while true
                default:
                    break outerLoop
                }
            } while true
        } catch Error.endOfFile {
            // This is fine
        }

        if !hasDigits {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }

        let sign = isNegative ? -1: 1
        if hasDecimal || hasExponent {
            divisor /= 10
            var number = Double(sign) * (Double(integer) + (Double(decimal) / divisor))
            if hasExponent {
                if positiveExponent {
                    for _ in 1...exponent {
                        number *= Double(10)
                    }
                } else {
                    for _ in 1...exponent {
                        number /= Double(10)
                    }
                }
            }
            return Value.double(number)
        } else {
            var number: Int64
            if isNegative {
                if integer > UInt64(Int64.max) + 1 {
                    throw Error.invalidNumber(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
                } else if integer == UInt64(Int64.max) + 1 {
                    number = Int64.min
                } else {
                    number = Int64(integer) * -1
                }
            } else {
                if integer > UInt64(Int64.max) {
                    throw Error.invalidNumber(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
                } else {
                    number = Int64(integer)
                }
            }

            if number < Int64(Int.max) {
                return Value.integer(Int(number))
            } else {
                return Value.double(Double(number))
            }
        }
    }

    func nextBool() throws -> Value {
        var expectedWord: [UnicodeScalar]
        var expectedBool: Bool
        let lineNumAtStart = lineNumber
        let charNumAtStart = charNumber
        if scalar == trueToken[0] {
            expectedWord = trueToken
            expectedBool = true
        } else if scalar == falseToken[0] {
            expectedWord = falseToken
            expectedBool = false
        } else {
            throw Error.unexpectedCharacter(lineNumber: lineNumber, characterNumber: charNumber)
        }
        do {
            let word = try [scalar] + nextScalars(count: UInt(expectedWord.count - 1))
            if word != expectedWord {
                throw Error.unexpectedKeyword(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
            }
        } catch Error.endOfFile {
            throw Error.unexpectedKeyword(lineNumber: lineNumAtStart, characterNumber: charNumAtStart)
        }
        return Value.boolean(expectedBool)
    }

    func nextNull() throws -> Value {
        let word = try [scalar] + nextScalars(count: 3)
        if word != nullToken {
            throw Error.unexpectedKeyword(lineNumber: lineNumber, characterNumber: charNumber-4)
        }
        return Value.null
    }
}

private let leftSquareBracket = UnicodeScalar(0x005b)!
private let leftCurlyBracket = UnicodeScalar(0x007b)!
private let rightSquareBracket = UnicodeScalar(0x005d)!
private let rightCurlyBracket = UnicodeScalar(0x007d)!
private let colon = UnicodeScalar(0x003A)!
private let comma = UnicodeScalar(0x002C)!
private let zeroScalar = "0".unicodeScalars.first!
private let negativeScalar = "-".unicodeScalars.first!
private let plusScalar = "+".unicodeScalars.first!
private let decimalScalar = ".".unicodeScalars.first!
private let quotationMark = UnicodeScalar(0x0022)!
private let carriageReturn = UnicodeScalar(0x000D)!
private let lineFeed = UnicodeScalar(0x000A)!

private let reverseSolidus = UnicodeScalar(0x005C)!
private let solidus = UnicodeScalar(0x002F)!
private let backspace = UnicodeScalar(0x0008)!
private let formFeed = UnicodeScalar(0x000C)!
private let tabCharacter = UnicodeScalar(0x0009)!

private let trueToken = [UnicodeScalar]("true".unicodeScalars)
private let falseToken = [UnicodeScalar]("false".unicodeScalars)
private let nullToken = [UnicodeScalar]("null".unicodeScalars)

private let escapeMap = [
    "/".unicodeScalars.first!: solidus,
    "b".unicodeScalars.first!: backspace,
    "f".unicodeScalars.first!: formFeed,
    "n".unicodeScalars.first!: lineFeed,
    "r".unicodeScalars.first!: carriageReturn,
    "t".unicodeScalars.first!: tabCharacter
]

private let hexStrings = [
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "a",
    "b",
    "c",
    "d",
    "e",
    "f"
]
