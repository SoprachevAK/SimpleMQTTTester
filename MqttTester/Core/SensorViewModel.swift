//
//  SensorViewModel.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 11.03.2023.
//

import Foundation
import Combine
import CoreMotion

protocol SensorSendData {
    func getSensorData() -> String
    func subscribe(_ listener: AnyObject, action: @escaping Event<Any>.EventHandler)
    var count: Int { get }
}

struct DataModel: Identifiable {
    let id: String = UUID().uuidString
    let axis: String
    var value: [Double] = Array(repeating: 0, count: 200)
    
    mutating func add(_ newValue: Double) {
        value.removeFirst()
        value.append(newValue)
    }
}


class SensorViewModel: ObservableObject, SensorSendData {
    var count: Int = 200
    
    let motionManager = CMMotionManager()

    private var x: DataModel = .init(axis: "x")
    private var y: DataModel = .init(axis: "y")
    private var z: DataModel = .init(axis: "z")

    @Published var data: [DataModel] = []
    
    let onChange = Event<Any>()


    init() {
        motionManager.accelerometerUpdateInterval = 1/30
        motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
            self.updateProperties(with: data)
        }
    }

    private func updateProperties(with accelerometerData: CMAccelerometerData?) {
        if let data = motionManager.accelerometerData {
            x.add(data.acceleration.x)
            y.add(data.acceleration.y)
            z.add(data.acceleration.z)
            
            onChange.notify(0)

            self.data = [self.x, self.y, self.z]
        }
    }
    
    func getSensorData() -> String {
        if let data = motionManager.accelerometerData {
            return "x: \(data.acceleration.x); y: \(data.acceleration.y); z: \(data.acceleration.z)"
        }
        return "-"
    }
    
    func subscribe(_ listener: AnyObject, action: @escaping Event<Any>.EventHandler) {
        onChange.addListener(listener, action: action)
    }
}
