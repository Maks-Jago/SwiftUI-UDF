//
//  SwiftUIView.swift
//  
//
//  Created by Oksana Fedorchuk on 07.04.2024.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        Text("Hello, World!")
            .alert(statusWrapper: .constant(.init(theStyle: .init(alertType: .message, title: "The title", body: "Body", message: "My message"))))
    }
}

#Preview {
    SwiftUIView()
}
