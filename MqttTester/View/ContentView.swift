//
//  ContentView.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 10.03.2023.
//

import SwiftUI
import CocoaMQTT

struct ContentView: View {
    @StateObject var mqtt = MqttViewModel()
    
    @State var alertError: String?
    @StateObject var currentTopic = TopicSelector.CurrentItem()
    
    @State var currentProfile: ProfileSelector.Item = .forward

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Group {
                        if currentProfile.isForward {
                            Section() {
                                TextField("Username", text: $mqtt.username)
                                SecureField("Password", text: $mqtt.password)
                            } header: {
                                HStack {
                                    Text("Profile")
                                    Spacer()
                                    NavigationLink(destination: ProfileSelector(currentProfile: $currentProfile)) {
                                        Text("More")
                                            .textCase(nil)
                                    }
                                }
                            }
                        } else {
                            NavigationLink(destination: ProfileSelector(currentProfile: $currentProfile)) {
                                HStack {
                                    Text("Profile")
                                    Spacer()
                                    Text(currentProfile.title)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Section(header: Text("Server")) {
                            TextField("Host", text: $mqtt.host)
                            TextField("Port", text: Binding(
                                get: { String(mqtt.port)},
                                set: { mqtt.port = UInt16($0) ?? 0 }
                            ))
                            .keyboardType(.numberPad)
                            Toggle("Allow any certs", isOn: $mqtt.allowSerts)
                        }
                        
                        Section(footer: Text("You can change it after connecting")) {
                            TopicSelector(currentTopic: currentTopic)
                        }
                        
                        Button(action: {
                            mqtt.currentProfile = currentProfile
                            mqtt.connect()
                        }) {
                            if mqtt.status == .connecting {
                                HStack {
                                    Text("Connecting")
                                    Spacer()
                                    ProgressView()
                                }
                            } else {
                                Text(mqtt.status == .connected ? "Connected" : "Connect")
                            }
                        }
                        
                    }
                    .disabled(mqtt.status != .disconnected)
                    
                    if mqtt.status == .connecting {
                        Button("Cancel") {
                            mqtt.disconnect()
                        }
                    }
                }
                .navigationBarTitle("Settings")
                
            }
            .navigationDestination(isPresented: $mqtt.connected) {
                Connected(mqtt: mqtt, currentTopic: currentTopic)
            }
            .alert(isPresented: Binding(get: { alertError != nil }, set: { t in alertError = nil; mqtt.error = nil })) {
                Alert(title: Text("Connection error"), message: Text(mqtt.error ?? "unknown"))
            }
            
        }
        .onChange(of: mqtt.error) { e in
            if e != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    alertError = e
                }
            }
        }
        .onAppear {
            currentProfile = mqtt.currentProfile
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
