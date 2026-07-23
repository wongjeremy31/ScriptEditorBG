// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ScriptEditorBG",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ScriptEditorBG", targets: ["ScriptEditorBG"])
    ],
    targets: [
        .executableTarget(
            name: "ScriptEditorBG",
            dependencies: [],
            path: "Sources/ScriptEditorBG"
        )
    ]
)
