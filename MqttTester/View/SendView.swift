//
//  SendView.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 10.03.2023.
//

import SwiftUI
import Charts

enum Variant: Double {
    case none = 1000000000
    case hz1 = 1
    case hz2 = 0.5
    case hz02 = 5
    
    var description: String {
        switch self {
        case .none:
            return "None"
        case .hz02:
            return "1/5 Hz"
        case .hz1:
            return "1 Hz"
        case .hz2:
            return "2 Hz"
        }
    }
    
    static var all: [Variant] { [Variant.none, Variant.hz02, Variant.hz1, Variant.hz2] }
}

struct ChartView: View {
    @ObservedObject var sensor: SensorViewModel
    @ObservedObject var sender: SenderViewModel
    
    var body: some View {
        Chart {
            ForEach(sensor.data) { data in
                ForEach(Array(data.value.enumerated()), id: \.offset) { index, element in
                    LineMark(x: .value("Index", Double(index - data.value.count)),
                             y: .value("Value", element))

                }
                .foregroundStyle(by: .value("Axis", data.axis))
            }


            ForEach(sender.data, id: \.id) { t in
                RuleMark(x: .value("Send", Double(t.value)))
                    .foregroundStyle(t.sended ? .green : .red)
                    .lineStyle(.init(lineWidth: 1))
                    .opacity(0.5)
            }
        }
        .chartXScale(domain: -200...0)
        .chartXAxis {
            AxisMarks(values: .stride(by: 30))
        }
        .frame(height: 300)
    }
}

struct SendView: View {
    var mqtt: MqttViewModel
    var sensor: SensorViewModel
    var sender: SenderViewModel
    var currentTopic: TopicSelector.CurrentItem
    
    
    init(mqtt: MqttViewModel, currentTopic: TopicSelector.CurrentItem? = nil) {
        self.mqtt = mqtt
        let sensor = SensorViewModel()
        self.sensor = sensor
        sender = SenderViewModel(sensorData: sensor, mqqt: mqtt)
        self.currentTopic = currentTopic ?? TopicSelector.CurrentItem()
    }
    
    @State var variant: Variant = .none
    @State var lastSend = Date.now
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let _ = Self._printChanges()
        NavigationStack {
            List {
                Section("Settings") {
                    Picker(selection: $variant, label: Text("Autosend frequency")) {
                        ForEach(Variant.all, id: \.self) { variant in
                            Text(variant.description).tag(variant)
                        }
                    }
                    TopicSelector(currentTopic: currentTopic)
                }
                
                Section {
                    Button("Publish") {
                        mqtt.publish(topic: currentTopic.topicString, data: sensor.getSensorData())
                    }
                }
                
                Section {
                    ChartView(sensor: sensor, sender: sender)
                }
            }
        }
        .navigationTitle(Text("Sending"))
        .onReceive(timer) { t in
            if Double(lastSend.distance(to: t)) > variant.rawValue {
                lastSend = t
                mqtt.publish(topic: currentTopic.topicString, data: sensor.getSensorData())
            }
        }
        
    }
}

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView(mqtt: MqttViewModel())
    }
}
