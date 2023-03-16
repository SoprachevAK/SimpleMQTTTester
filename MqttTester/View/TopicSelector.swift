//
//  TopicSelector.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 13.03.2023.
//

import SwiftUI
import Combine

private struct TopicSelectorContent: View {
    @Environment(\.dismiss) var dismiss
    
    
    @ObservedObject var currentTopic: TopicSelector.CurrentItem
    var subscriptions: [String] = []
    
    @AppStorage("topics") var topics: [TopicSelector.Item] = []
    @State var editMode = EditMode.inactive
    
    var body: some View {
        List {
            Section() {
                ForEach($topics) { $topic in
                    Button(action: {
                        if editMode == EditMode.inactive {
                            currentTopic.topic = topic
                            dismiss()
                        }
                    }, label: {
                        HStack(spacing: 0) {
                            if !subscriptions.isEmpty {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(!editMode.isEditing && subscriptions.contains(topic.title) ? .green : .clear)
                                    .font(.caption2)
                                    .offset(x: editMode.isEditing ? -15 : 0)
                                    .frame(width: 0)
                            }
                            
                            ZStack(alignment: .leading) {
                                Text("!@#")
                                    .foregroundColor(.clear)
                                
                                TextField(editMode.isEditing ? "Topic" : "Empty", text: $topic.title)
                                    .disabled(!editMode.isEditing)
                                    .foregroundColor(.primary)
                            }
                            .padding(.leading, editMode.isEditing || subscriptions.isEmpty ? 0 : 15)
                            
                            Spacer()
                            
                            if !editMode.isEditing && currentTopic.topic == topic {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                    })
                }
                .onDelete(perform: onDelete)
            }
        }
        .navigationBarBackButtonHidden(editMode != EditMode.inactive)
        .navigationBarItems(leading: addButton, trailing: EditButton())
        .environment(\.editMode, $editMode)
        .navigationTitle(Text("Topics"))
    }
    
    
    var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(EmptyView())
        default:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus") })
        }
    }
    
    func onAdd() {
        topics.append(.init(title: ""))
    }
    
    func onDelete(at offsets: IndexSet) {
        topics.remove(atOffsets: offsets)
        
        if let topic = currentTopic.topic, !topics.contains(topic) {
            self.currentTopic.topic = nil
        }
    }
}

struct TopicSelector: View {
    
    class CurrentItem: ObservableObject {
        @Published var topic: Item? = nil
        
        var topicString: String {
            topic?.title ?? ""
        }
    }
    
    struct Item: Identifiable, Equatable, Codable {
        var id = UUID()
        var title: String
        
        init (title: String) {
            self.title = title
        }
    }
    
    
    
    @ObservedObject var currentTopic: CurrentItem
    var subscriptions: [String] = []
    
    
    var body: some View {
        NavigationLink(destination: TopicSelectorContent(currentTopic: currentTopic, subscriptions: subscriptions), label: {
            HStack {
                Text("Topic")
                Spacer()
                Text(currentTopic.topic?.title ?? "Select").foregroundColor(.secondary)
            }
        })
    }
    
}

struct TopicSelector_Previews: PreviewProvider {
    
    static var previews: some View {
        
        NavigationStack {
            List {
                TopicSelector(currentTopic: .init(), subscriptions: ["TEST"])
            }
        }
    }
}
