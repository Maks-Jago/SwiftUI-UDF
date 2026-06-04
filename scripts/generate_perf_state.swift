import Foundation

func generate(count: Int) -> String {
    var out = ""
    out += "// Generated file for N = \(count) performance tests\n"
    out += "import UDF\n"
    out += "import SwiftUI\n\n"
    
    // Generate Forms - explicitly using UDF.Form
    for i in 0..<count {
        out += "struct PerfForm_\(count)_\(i): UDF.Form {}\n"
    }
    out += "\n"
    
    // Generate Containers
    for i in 0..<count {
        out += "struct PerfContainer_\(count)_\(i): BindableContainer {\n"
        out += "    typealias ContainerComponent = PerfComponent\n"
        out += "    var id: Int\n"
        out += "    func scope(for state: AppState_\(count)) -> Scope {\n"
        out += "        state.form_\(i)[id]\n"
        out += "    }\n"
        out += "    func map(store: EnvironmentStore<AppState_\(count)>) -> PerfComponent.Props {\n"
        out += "        .init()\n"
        out += "    }\n"
        out += "}\n\n"
    }
    
    // Generate AppState
    out += "struct AppState_\(count): AppReducer {\n"
    for i in 0..<count {
        out += "    @BindableReducer(PerfForm_\(count)_\(i).self, bindedTo: PerfContainer_\(count)_\(i).self)\n"
        out += "    var form_\(i): BindableReducer<PerfContainer_\(count)_\(i), PerfForm_\(count)_\(i)>\n"
    }
    out += "}\n"
    
    return out
}

let targetDir = "Tests/SwiftUI-UDF-Tests/BindableReducers/"
try! generate(count: 100).write(toFile: targetDir + "GeneratedPerformanceAppState100.swift", atomically: true, encoding: .utf8)
try! generate(count: 500).write(toFile: targetDir + "GeneratedPerformanceAppState500.swift", atomically: true, encoding: .utf8)
try! generate(count: 1000).write(toFile: targetDir + "GeneratedPerformanceAppState1000.swift", atomically: true, encoding: .utf8)
print("Files generated successfully!")
