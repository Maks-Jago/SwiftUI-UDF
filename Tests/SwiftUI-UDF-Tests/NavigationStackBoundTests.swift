//===--- NavigationStackBoundTests.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI
@testable import UDF
import Testing

struct NavigationStackBoundTests {
    @Test
    @MainActor
    func navigationStackBoundWithNavigationPath() {
        let path = Binding.constant(NavigationPath())
        let view = NavigationStackBound(path: path) {
            Text("Root")
        }
        
        let desc = "\(view)"
        // Verify the struct initializes successfully and is correctly identified
        #expect(desc.contains("NavigationStackBound"))
    }
    
    @Test
    @MainActor
    func navigationStackBoundWithCollection() {
        let path = Binding.constant([Int]())
        let view = NavigationStackBound(path: path) {
            Text("Root")
        }
        
        let desc = "\(view)"
        // Verify the struct initializes successfully and is correctly identified
        #expect(desc.contains("NavigationStackBound"))
    }
    
    @Test
    @MainActor
    func deprecatedNavigationStackWithNavigationPathResolves() {
        let path = Binding.constant(NavigationPath())

        let view = NavigationStack(path: path) {
            Text("Root")
        }
        
        let desc = "\(view)"
        // The shadowed function delegates to the standard native NavigationStack
        #expect(desc.contains("NavigationStack"))
    }
    
    @Test
    @MainActor
    func deprecatedNavigationStackWithCollectionResolves() {
        let path = Binding.constant([String]())

        let view = NavigationStack(path: path) {
            Text("Root")
        }
        
        let desc = "\(view)"
        // The shadowed function delegates to the standard native NavigationStack
        #expect(desc.contains("NavigationStack"))
    }
}
