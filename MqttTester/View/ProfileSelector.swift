//
//  ProfileSelector.swift
//  MqttTester
//
//  Created by Andrei Soprachev on 13.03.2023.
//

import SwiftUI

struct ProfileSelector: View {
    
    struct Item: Identifiable, Equatable, Codable {
        var id = UUID()
        var login: String
        var password: String
        var label: String
        var clientId: String
        
        let isForward: Bool
        
        static var forward: Item {
            .init(isForward: true)
        }
        
        init(login: String = "", password: String = "", clientId: String = "", label: String = "", isForward: Bool = false) {
            self.login = login
            self.password = password
            self.clientId = clientId
            self.label = label
            self.isForward = isForward
        }
        
        mutating func updateTo(_ item: Item) {
            login = item.login
            password = item.password
            label = item.label
            clientId = item.clientId
        }
        
        var title: String {
            return label.isEmpty ? login : label
        }
    }
    
    
    @AppStorage("profiles") var profiles: [Item] = []
    @Binding var currentProfile: Item
    
    @State var editMode = EditMode.inactive
    @State var isEdit = false
    @State var isAdd = false
    @State var editingProfile: Item = .init(login: "", password: "", label: "")
    @State var editingProfileId: UUID = .init()
    
    var body: some View {
        NavigationStack {
            List {
                Section() {
                    Button(action: {
                        if editMode == .inactive {
                            currentProfile = .forward
                        }
                    }) {
                        HStack {
                            Text("Enter forward").foregroundColor(.primary)
                            Spacer()
                            if editMode == .inactive && currentProfile.isForward { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                        }
                    }
                } footer: {
                    Text("Enter login and password on last page")
                }
                
                Section() {
                    ForEach($profiles) { $profile in
                        Group {
                            if editMode == EditMode.inactive {
                                Button(action: {
                                    currentProfile = profile
                                }) {
                                    HStack {
                                        Text(profile.title).foregroundColor(.primary)
                                        Spacer()
                                        if currentProfile.id == profile.id { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                                    }
                                }
                            } else {
                                NavigationLink(destination: EmptyView()) {
                                    Text(profile.title)
                                        .foregroundColor(.primary)
                                }
                                .environment(\.editMode, .constant(.inactive))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingProfile = profile
                                    editingProfileId = profile.id
                                    isEdit.toggle()
                                }
                            }
                        }
                    }
                    .onDelete(perform: onDelete)
                }
            }
            .sheet(isPresented: $isEdit) { editView }
            .sheet(isPresented: $isAdd) { addView }
            .navigationBarBackButtonHidden(editMode != EditMode.inactive)
            .navigationBarItems(leading: addButton, trailing: EditButton())
            .environment(\.editMode, $editMode)
            .navigationTitle(Text("Profiles"))
        }
    }
    
    var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(EmptyView())
        default:
            return AnyView(Button(action: onAdd) { Image(systemName: "plus") })
        }
    }
    
    var editView: some View {
        NavigationStack {
            Form {
                Section(footer: Text("Short name for display in list")) {
                    TextField("Label", text: $editingProfile.label)
                }
                
                Section(header: Text("profile")) {
                    TextField("Login", text: $editingProfile.login)
                    SecureField("Password", text: $editingProfile.password)
                }
                
                Section(header: Text("client")) {
                    TextField("ClientId", text: $editingProfile.clientId)
                }
            }
            .navigationTitle(Text("Edit profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        isEdit = false
                        profiles[profiles.firstIndex(where: { $0.id == editingProfileId })!].updateTo(editingProfile)
                    }
                    .bold()
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isEdit = false
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    var addView: some View {
        NavigationStack {
            Form {
                Section(footer: Text("Отображаемое название профиля при выборе")) {
                    TextField("Label", text: $editingProfile.label)
                }
                
                Section(header: Text("profile")) {
                    TextField("Login", text: $editingProfile.login)
                    SecureField("Password", text: $editingProfile.password)
                }
                
                Section(header: Text("client")) {
                    TextField("ClientId", text: $editingProfile.clientId)
                }
            }
            .navigationTitle(Text("Edit profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        isAdd = false
                        profiles.append(editingProfile)
                    }
                    .bold()
                    .disabled(editingProfile.label.isEmpty && editingProfile.login.isEmpty)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAdd = false
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    func onAdd() {
        editingProfile = .init()
        isAdd.toggle()
    }
    
    func onDelete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        
        if !profiles.map({ $0.id }).contains(currentProfile.id) {
            currentProfile = .forward
        }
    }
}

struct ProfileSelector_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSelector(currentProfile: .constant(.init()))
    }
}
