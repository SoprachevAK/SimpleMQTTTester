//
//  MqttViewModel.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 11.03.2023.
//

import Combine
import CocoaMQTT

class MqttViewModel: ObservableObject {
    
    struct Message: Identifiable, Equatable {
        enum Level {
            case message
            case succes
            case warning
            case error
            case info
        }
        
        var id = UUID()
        var content: String
        var level: Level
    }
    
    var mqtt: CocoaMQTT!
    
    @Published var clientID: String = "Process-" + String(ProcessInfo().processIdentifier)
    @Published(key: "currentProfile", convertJson: true) var currentProfile: ProfileSelector.Item = .forward
    @Published(key: "username") var username: String = ""
    @Published(key: "password") var password: String = ""
    @Published(key: "host") var host: String = ""
    
    @Published(key: "port") var port: UInt16 = 8883
    @Published(key: "allowSerts") var allowSerts: Bool = false
    
    @Published var status: CocoaMQTTConnState = .disconnected
    
    @Published var connected: Bool = false
    @Published var error: String?
    
    @Published var messages: [Message] = []
    @Published var subscriptions: [String] = []
    
    let didPublishMessage = Event<UInt16>()
    let didPublishAck = Event<UInt16>()
    
    private var cancellableSet: Set <AnyCancellable> = []
    
    init() {
        $status
            .map { t in return t == .connected }
            .assign(to: \.connected, on: self)
            .store(in: &cancellableSet)
    }
    
    func connect() {
        mqtt = CocoaMQTT(clientID: currentProfile.isForward ? clientID : currentProfile.clientId, host: host, port: port)
        mqtt.username = currentProfile.isForward ? username : currentProfile.login
        mqtt.password = currentProfile.isForward ? password : currentProfile.password
        
        
        mqtt.enableSSL = true
        mqtt.allowUntrustCACertificate = allowSerts
        
        mqtt.delegate = self
        
        _ = mqtt.connect(timeout: 10)
    }
    
    func disconnect() {
        mqtt.disconnect()
    }
    
    func publish(topic: String, data: String) {
        mqtt.publish(topic, withString: data)
    }
    
    func subscribe(topic: String, qos: CocoaMQTTQoS = .qos1) {
        messages.append(.init(content: "Connecting to \(topic) with \(qos.description)", level: .info))
        mqtt.subscribe(topic, qos: qos)
    }
    
    func unsubscribe(topic: String) {
        mqtt.unsubscribe(topic)
    }
    
    func unsubscribeAll() {
        mqtt.unsubscribe(Array(mqtt.subscriptions.keys))
    }
}

extension MqttViewModel: CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        status = state
        subscriptions = Array(mqtt.subscriptions.keys)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        self.didPublishMessage.notify(id)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        self.didPublishAck.notify(id)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        let message = message.string ?? "[\(message.payload.map({ String($0) }).joined(separator: ", "))]"
        messages.append(.init(content: message, level: .message))
        print("didReceiveMessage: \(message)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        
        subscriptions = Array(mqtt.subscriptions.keys)
        
        let messages = Array(success.map { ($0.key as? String, $0.value as? UInt16) })
            .compactMap({
                if let key = $0.0, let value = $0.1 {
                    return Message(content: "Succes connected to topic: \(key) with QOS: \(value)", level: .succes)
                }
                return nil
            })
            
        self.messages.append(contentsOf: messages)
        
        failed.forEach({
            self.messages.append(.init(content: "Faild connected to topic: \($0)", level: .error))
        })
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        subscriptions = Array(mqtt.subscriptions.keys)
        
        topics.forEach({
            self.messages.append(.init(content: "Unsubscribe topic: \($0)", level: .warning))
        })
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) { }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) { }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        if let err {
            error = err.localizedDescription
            print("mqttDidDisconnect error: \(err.localizedDescription)")
        }
    }
}

