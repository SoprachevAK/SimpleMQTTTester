//
//  SubscribeView.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 13.03.2023.
//

import SwiftUI
import CocoaMQTT

struct ListButtonStyle: ButtonStyle {
    var padding: CGFloat
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(
                configuration.isPressed ? Color(uiColor: .separator) : Color(uiColor: .secondarySystemGroupedBackground))
    }
}

struct ListNavigationLinkStyle: ButtonStyle {
    var padding: CGFloat
    func makeBody(configuration: Self.Configuration) -> some View {
        
        HStack {
            configuration.label
                .foregroundColor(.primary)
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.6))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(
            configuration.isPressed ? Color(uiColor: .separator) : Color(uiColor: .secondarySystemGroupedBackground))
    }
}

struct SubscribeView: View {
    @ObservedObject var mqtt: MqttViewModel
    @State var messages: [MqttViewModel.Message] = []
    @State var qosVariant: CocoaMQTTQoS = .qos1
    
    @ObservedObject var currentTopic: TopicSelector.CurrentItem

    
    var picker: some View {
        Menu {
            Picker(selection: $qosVariant, label: EmptyView()) {
                ForEach([CocoaMQTTQoS.qos0, CocoaMQTTQoS.qos1, CocoaMQTTQoS.qos2], id: \.self) { variant in
                    Text(variant.description).tag(variant)
                }
            }
        } label: {
            HStack {
                Text("qosVariant")
                    .foregroundColor(.primary)
                Spacer()
                Text(qosVariant.description)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.6))
                    .fontWeight(.semibold)
            }
            .padding(11.75)
        }
    }
    
    var isSubscribed: Bool {
        mqtt.subscriptions.contains(currentTopic.topicString)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VStack(spacing: 0) {
                    Group {
                        TopicSelector(currentTopic: currentTopic, subscriptions: mqtt.subscriptions)
                            .buttonStyle(ListNavigationLinkStyle(padding: 11.75))
                        
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        picker
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        Button(action: {
                            withAnimation {
                                if isSubscribed {
                                    mqtt.unsubscribe(topic: currentTopic.topicString)
                                } else {
                                    mqtt.subscribe(topic: currentTopic.topicString, qos: qosVariant)
                                }
                            }
                        }) {
                            Text(isSubscribed ? "Unsubscribe" : "Subscribe")
                                .foregroundColor(isSubscribed ? .red : .blue)
                        }
                        .buttonStyle(ListButtonStyle(padding: 11.75))
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                }
                .mask { RoundedRectangle(cornerRadius: 10, style: .continuous) }
                .padding(.horizontal)
                
                if messages.isEmpty {
                    Spacer()
                } else {
                    
                    HStack {
                        Text("Messages")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        Button(action: {
                            withAnimation {
                                mqtt.messages = []
                            }
                        }) {
                            Text("Clear")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding([.top, .leading, .trailing])
                    
                    List {
                        ForEach(messages.reversed(), id: \.id) { message in
                            Text(message.content)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10.0)
                                .padding(.vertical, 6.0)
                                .background (
                                    GeometryReader { geometry in
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(colorError(by: message.level))
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 5)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(Text("Subscribe"))
            .navigationBarTitleDisplayMode(.large)
            .onReceive(mqtt.$messages) { messages in
                DispatchQueue.main.async {
                    withAnimation {
                        self.messages = messages
                    }
                }
            }
        }
    }

    func colorError(by level: MqttViewModel.Message.Level) -> Color {
        switch level {
        case .message:
            return .blue
        case .succes:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .info:
            return .purple
        }
    }
}

struct SubscribeView_Previews: PreviewProvider {
    static var previews: some View {
        SubscribeView(mqtt: .init(), currentTopic: .init())
    }
}
