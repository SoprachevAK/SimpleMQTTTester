//
//  Sahred.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 11.03.2023.
//

import Foundation
import Combine
import UIKit

fileprivate var cancellables = [String : AnyCancellable] ()

extension Published {
    init(wrappedValue defaultValue: Value, key: String) {
        let value = UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue
        self.init(initialValue: value)
        cancellables[key] = projectedValue.sink { val in
            UserDefaults.standard.set(val, forKey: key)
        }
    }
    
    init(wrappedValue defaultValue: Value, key: String, convertJson: Bool = false) where Value: Codable {
        if convertJson {
            var value = defaultValue
            if let savedData = UserDefaults.standard.data(forKey: key),
               let decodedItem = try? JSONDecoder().decode(Value.self, from: savedData) {
                value = decodedItem
            }
            
            self.init(initialValue: value)
            
            let encoder = JSONEncoder()
            cancellables[key] = projectedValue.sink { val in
                if let encodedData = try? encoder.encode(val) {
                    UserDefaults.standard.set(encodedData, forKey: key)
                }
            }
        } else {
            let value = UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue
            self.init(initialValue: value)
            cancellables[key] = projectedValue.sink { val in
                UserDefaults.standard.set(val, forKey: key)
            }
        }
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

extension Optional: RawRepresentable where Wrapped: Codable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return json
    }
    
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let value = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = value
    }
}

class Event<T> {
    
    typealias EventHandler = (T) -> Void
    
    private struct Listener {
        weak var listener: AnyObject?
        var action: EventHandler
    }
    
    private var listeners: [ObjectIdentifier: Listener] = [:]
    
    public func addListener(_ listener: AnyObject, action: @escaping EventHandler) {
        let id = ObjectIdentifier(listener)
        listeners[id] = Listener(listener: listener, action: action)
    }
    
    public func removeListener(_ listener: AnyObject) {
        let id = ObjectIdentifier(listener)
        listeners.removeValue(forKey: id)
    }
    
    public func notify(_ subject: T) {
        for (id, listener) in listeners {
            if listener.listener == nil {
                listeners.removeValue(forKey: id)
                continue
            }
            
            listener.action(subject)
        }
    }
}
