# **SwiftSpreadable 🛠️✨**


SwiftSpreadable is a lightweight Swift package that provides a powerful macro-based solution for seamlessly merging optional properties in Swift structs. Designed to reduce boilerplate code, this package introduces the @Spreadable macro, which generates spread and mutatingSpread functions for your structs automatically.


# Features 🚀

	•	Automatic Code Generation: Use the @Spreadable macro to automatically generate spread(from:) and mutatingSpread(from:) functions.
	•	Simplified Property Merging: Merge optional properties from another instance with fallback to the current instance’s values.
	•	Focus on Optional Properties: Ensures that only structs with all-optional properties are eligible for the macro.
	•	Static and Mutating Functions: Includes both spread (returns a new instance) and mutatingSpread (modifies the existing instance) functions.


# Example Usage 📖

Input

```swift
import SwiftSpreadable

@Spreadable
struct Example {
    var a: String?
    var b: Int?
    var c: Double?
    var d: Float?
}
```

Generated Code

```swift
extension Example {
    func spread(from: Self) -> Self {
        Self(
            a: from.a ?? self.a,
            b: from.b ?? self.b,
            c: from.c ?? self.c,
            d: from.d ?? self.d
        )
    }

    mutating func mutatingSpread(from: Self) {
        self = Self(
            a: from.a ?? self.a,
            b: from.b ?? self.b,
            c: from.c ?? self.c,
            d: from.d ?? self.d
        )
    }
}
```

# Example in Action

```swift
let instance1 = Example(a: "Hello", b: nil, c: 1.23, d: nil)
let instance2 = Example(a: nil, b: 42, c: nil, d: 3.14)
```

Using `spread` (non-mutating)
```swift
let merged = instance1.spread(from: instance2)
print(merged) // Example(a: "Hello", b: 42, c: 1.23, d: 3.14)
```

Using `mutatingSpread`
```swift
var mutableInstance = instance1
mutableInstance.mutatingSpread(from: instance2)
print(mutableInstance) // Example(a: "Hello", b: 42, c: 1.23, d: 3.14)
```

# Installation 📦

Add SwiftSpreadable to your project using the Swift Package Manager (SPM):
	1.	In Xcode, navigate to File > Add Packages.
	2.	Enter the repository URL: https://github.com/your-username/swift-spreadable
	3.	Select the version and integrate the package into your project.

Or add it manually in your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/swift-spreadable.git", from: "1.0.0")
]
```


# Requirements ⚙️

	•	Swift 5.9+
	•	Compatible with macOS, iOS, tvOS, and watchOS projects.


# Contributing 🤝

We welcome contributions! Feel free to submit issues, feature requests, or pull requests to help improve SwiftSpreadable.


#License 📄


This project is licensed under the MIT License. See the LICENSE file for details.

With SwiftSpreadable, writing concise and clean code has never been easier. Give it a try and say goodbye to manual property merging! 🎉
