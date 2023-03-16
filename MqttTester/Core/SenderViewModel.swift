//
//  SenderViewModel.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 11.03.2023.
//

import Foundation
import Combine


class SenderViewModel: ObservableObject {
    struct DataModel: Identifiable {
        let id: UInt16
        var value: Double = 0
        var sended: Bool = false
        
        mutating func move() {
            value -= 1
        }
        
        mutating func send() {
            sended = true
        }
    }
    
    let sensorData: SensorSendData
    weak var mqqt: MqttViewModel?
    
    @Published var data: [DataModel] = []
    
    
    init(sensorData: SensorSendData, mqqt: MqttViewModel) {
        self.mqqt = mqqt
        self.sensorData = sensorData
        
        sensorData.subscribe(self, action: { [weak self] _ in
            if let self {
                for i in 0..<self.data.count {
                    self.data[i].move()
                }
                self.data = self.data.filter({ $0.value > -Double(sensorData.count) })
            }
        })
        
        mqqt.didPublishMessage.addListener(self) { [weak self] id in
            self?.data.append(.init(id: id))
        }
        
        mqqt.didPublishAck.addListener(self) { [weak self] id in
            if let self {
                for i in 0..<self.data.count {
                    if self.data[i].id == id {
                        self.data[i].send()
                        return
                    }
                }
            }
        }
    }
    
    
    
}
