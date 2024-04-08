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
            .alert(
                statusWrapper: .constant(
                    .init(
                        theStyle:
                                .init(
                                    title: "The title",
                                    body: "Body",
                                    message: "My message",
                                    actions: [
                                        .init(title: "Cancel", role: .cancel, action: {}),
                                        .init(title: "Ok"),
                                        .init(title: "Why", role: .destructive, action: {})
                                    ]
                                )
                    )
                )
            )
    }
}

#Preview {
    SwiftUIView()
}
