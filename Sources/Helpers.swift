public func prettyPrint(_ any: Any?) {
    print(prettyDescription(any), terminator: "\n\n")
}

public func prettyPrint(_ prepend: String, _ any: Any?) {
    print(prepend + prettyDescription(any), terminator: "\n\n")
}

public func prettyDescription(_ any: Any?) -> String {
    guard let (any, mirror) = deepUnwrap(any) else {
		return "nil"
	}
    
    if any is Void {
        return "Void"
    }

    if let int = any as? Int {
		return String(int)
    } else if let uint = any as? UInt {
        return String(uint)
    } else if let double = any as? Double {
		return String(double)
	} else if let float = any as? Float {
		return String(float)
    } else if let bool = any as? Bool {
        return String(bool)
    } else if let string = any as? String {
		return "\"\(string)\""
	}

    if let any = any as? LosslessStringConvertible {
        return any.description
    }
    
    func indentedString(_ string: String) -> String {
        return string.characters
            .split(separator: "\r")
            .map(String.init)
            .map { $0.isEmpty ? "" : "\r    \($0)" }
            .joined(separator: "")
    }
    
    var properties = Array(mirror.children)

    var typeName = String(describing: mirror.subjectType)
    if typeName.hasSuffix(".Type") {
        typeName = ""
    } else { typeName = "<\(typeName)> " }
    
    guard let displayStyle = mirror.displayStyle else {
        return "\(typeName)\(String(describing: any))"
    }
    
    switch displayStyle {
    case .tuple:
        if properties.isEmpty { return "()" }
        
        var string = "("
        
        for (index, property) in properties.enumerated() {
            if property.label!.characters.first! == "." {
                string += prettyDescription(property.value)
            } else {
                string += "\(property.label!): \(prettyDescription(property.value))"
            }
            
            string += (index < properties.count - 1 ? ", " : "")
        }
        
        return string + ")"
    case .collection, .set:
        if properties.isEmpty { return "[]" }
        
        var string = "["
    
        for (index, property) in properties.enumerated() {
            string += indentedString(prettyDescription(property.value) + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
    case .dictionary:
        if properties.isEmpty { return "[:]" }
        
        var string = "["
        
        for (index, property) in properties.enumerated() {
            let pair = Array(Mirror(reflecting: property.value).children)
            
            string += indentedString("\(prettyDescription(pair[0].value)): \(prettyDescription(pair[1].value))"
                    + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
    case .enum:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        if properties.isEmpty { return "\(mirror.subjectType)." + String(describing: any) }
        
        var string = "\(mirror.subjectType).\(properties.first!.label!)"
        
        let associatedValueString = prettyDescription(properties.first!.value)
        
        if associatedValueString.characters.first! == "(" {
            string += associatedValueString
        } else {
            string += "(\(associatedValueString))"
        }
        
        return string
    case .struct, .class:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        var superclassMirror = mirror.superclassMirror
        repeat {
            if let superChildren = superclassMirror?.children {
                properties.append(contentsOf: superChildren)
            }
            
            superclassMirror = superclassMirror?.superclassMirror
        } while superclassMirror != nil
        
        if properties.isEmpty { return "\(typeName)\(String(describing: any))" }
        
        var string = "\(typeName){"
        
        for (index, property) in properties.enumerated() {
            string += indentedString("\(property.label!): \(prettyDescription(property.value))"
                    + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r}"
    case .optional: fatalError()
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
