//
//  Connected.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 13.03.2023.
//

import SwiftUI

struct Connected: View {
    var mqtt: MqttViewModel
    var currentTopic: TopicSelector.CurrentItem
    
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Accelerometer") {
                        SendView(mqtt: mqtt, currentTopic: currentTopic)
                    }
                    
                    NavigationLink("Subscribe") {
                        SubscribeView(mqtt: mqtt, currentTopic: currentTopic)
                    }
                }
                
                
                Button("Disconnect") {
                    mqtt.disconnect()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle(Text("Connected"))
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden()
    }
}

struct Connected_Previews: PreviewProvider {
    static var previews: some View {
        Connected(mqtt: .init(), currentTopic: .init())
    }
}
