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
                                .init(error: "My error")
                    )
                )
            )
    }
}

#Preview {
    SwiftUIView()
}
