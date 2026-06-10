//===--- DialogComponentParserTests.swift ---------------------------------===//
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

@MainActor
struct DialogComponentParserTests {
    
    @Test("Parsing an empty array produces an empty payload")
    func emptyArrayProducesEmptyPayload() {
        let payload = DialogComponentParser.parse([])
        
        #expect(payload.title() == "")
        #expect(payload.message() == nil)
        #expect(payload.icon == nil)
        #expect(payload.customContentView == nil)
        #expect(payload.actions.isEmpty)
    }
    
    @Test("Parsing a single instance of each component type populates the payload correctly")
    func parsePopulatesPayloadCorrectly() {
        let components: [DialogComponent] = [
            DialogTitle("My Title"),
            DialogMessage("My Message"),
            DialogIcon { Image(systemName: "star") },
            DialogView { Text("Custom SwiftUI View") },
            DialogButton(title: "OK", action: {})
        ]
        
        let payload = DialogComponentParser.parse(components)
        
        #expect(payload.title() == "My Title")
        #expect(payload.message() == "My Message")
        #expect(payload.icon != nil)
        #expect(payload.customContentView != nil)
        #expect(payload.actions.count == 1)
        
        let action = payload.actions.first as? DialogButton
        #expect(action?.title == "OK")
    }
    
    @Test("When multiple values of the same component type are passed, the last one overwrites previous ones")
    func lastComponentWinsForSingularProperties() {
        let components: [DialogComponent] = [
            DialogTitle("First Title"),
            DialogMessage("First Message"),
            DialogIcon { Image(systemName: "circle") },
            DialogView { Text("First View") },
            
            DialogTitle("Second Title"),
            DialogMessage("Second Message"),
            DialogIcon { Image(systemName: "star") },
            DialogView { Text("Second View") }
        ]
        
        let payload = DialogComponentParser.parse(components)
        
        // Assert that all singular properties resolved to the *second* set of values
        #expect(payload.title() == "Second Title")
        #expect(payload.message() == "Second Message")
        #expect(payload.icon != nil)
        #expect(payload.customContentView != nil)
    }
    
    @Test("Dialog actions correctly append sequentially and do NOT overwrite each other")
    func multipleActionsAreAppended() {
        let components: [DialogComponent] = [
            DialogButton(title: "Button 1", action: {}),
            DialogButton(title: "Button 2", action: {}),
            DialogButton(title: "Button 3", action: {})
        ]
        
        let payload = DialogComponentParser.parse(components)
        
        #expect(payload.actions.count == 3)
        #expect((payload.actions[0] as? DialogButton)?.title == "Button 1")
        #expect((payload.actions[1] as? DialogButton)?.title == "Button 2")
        #expect((payload.actions[2] as? DialogButton)?.title == "Button 3")
    }
    
    @Test("Unhandled or unknown component types are ignored silently")
    func unhandledComponentTypesAreIgnored() {
        struct UnhandledMockComponent: DialogComponent {}
        
        let components: [DialogComponent] = [
            DialogTitle("Valid Title"),
            UnhandledMockComponent(), // Should hit default: break
            DialogMessage("Valid Message")
        ]
        
        let payload = DialogComponentParser.parse(components)
        
        #expect(payload.title() == "Valid Title")
        #expect(payload.message() == "Valid Message")
        #expect(payload.actions.isEmpty)
        #expect(payload.icon == nil)
        #expect(payload.customContentView == nil)
    }
}
