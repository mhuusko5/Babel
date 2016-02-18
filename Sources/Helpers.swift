public func prettyPrint(any: Any) {
    print(prettyDescription(any), terminator: "\n\n")
}

public func prettyPrint(prepend: String, _ any: Any) {
    print(prepend + prettyDescription(any), terminator: "\n\n")
}

public func prettyDescription(any: Any) -> String {
    guard let any = deepUnwrap(any) else {
		return "nil"
	}
    
    if any is Void {
        return "Void"
    }
	
	if let int = any as? Int {
		return String(int)
	} else if let double = any as? Double {
		return String(double)
	} else if let float = any as? Float {
		return String(float)
	} else if let bool = any as? Bool {
		return String(bool)
	} else if let string = any as? String {
		return "\"\(string)\""
	}
    
    func indentedString(string: String) -> String {
        return string.characters.split("\r").map(String.init).map { $0.isEmpty ? "" : "\r    \($0)" }.joinWithSeparator("")
    }
    
    let mirror = Mirror(reflecting: any)
    
    let properties = Array(mirror.children)

    var typeName = String(mirror.subjectType)
    if typeName.hasSuffix(".Type") {
        typeName = ""
    } else { typeName = "<\(typeName)> " }
    
    guard let displayStyle = mirror.displayStyle else {
        return "\(typeName)\(String(any))"
    }
    
    switch displayStyle {
    case .Tuple:
        if properties.count == 0 { return "()" }
        
        var string = "("
        
        for (index, property) in properties.enumerate() {
            if property.label!.characters.first! == "." {
                string += prettyDescription(property.value)
            } else {
                string += "\(property.label!): \(prettyDescription(property.value))"
            }
            
            string += (index < properties.count - 1 ? ", " : "")
        }
        
        return string + ")"
    case .Collection, .Set:
        if properties.count == 0 { return "[]" }
        
        var string = "["
    
        for (index, property) in properties.enumerate() {
            string += indentedString(prettyDescription(property.value) + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
    case .Dictionary:
        if properties.count == 0 { return "[:]" }
        
        var string = "["
        
        for (index, property) in properties.enumerate() {
            let pair = Array(Mirror(reflecting: property.value).children)
            
            string += indentedString("\(prettyDescription(pair[0].value)): \(prettyDescription(pair[1].value))" + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r]"
    case .Enum:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        if properties.count == 0 { return "\(mirror.subjectType)." + String(any) }
        
        var string = "\(mirror.subjectType).\(properties.first!.label!)"
        
        let associatedValueString = prettyDescription(properties.first!.value)
        
        if associatedValueString.characters.first! == "(" {
            string += associatedValueString
        } else {
            string += "(\(associatedValueString))"
        }
        
        return string
    case .Struct, .Class:
        if let any = any as? CustomDebugStringConvertible {
            return any.debugDescription
        }
        
        if properties.count == 0 { return "\(typeName)\(String(any))" }
        
        var string = "\(typeName){"
        
        for (index, property) in properties.enumerate() {
            string += indentedString("\(property.label!): \(prettyDescription(property.value))" + (index < properties.count - 1 ? ",\r" : ""))
        }
        
        return string + "\r}"
    case .Optional: fatalError("deepUnwrap must have failed... (it doesn't)")
    }
}

private func deepUnwrap(any: Any) -> Any? {
	let mirror = Mirror(reflecting: any)
	
	if mirror.displayStyle != .Optional {
		return any
	}
	
	if let child = mirror.children.first where child.label == "Some" {
		return deepUnwrap(child.value)
	}
	
	return nil
}
