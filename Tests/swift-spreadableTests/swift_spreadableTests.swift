import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SpreadableMacro)
import SpreadableMacro

let testMacros: [String: Macro.Type] = [
    "Spreadable": SpreadableMacro.self,
]
#endif

final class swift_spreadableTests: XCTestCase {
    func testMacro() throws {
        #if canImport(SpreadableMacro)
        assertMacroExpansion(
            """
            @Spreadable
            public struct Test {
                var a: String?
                var b: Int?
                var c: Double?
                var d: Float?
            
                mutating func mutateSpread(from: Self) {
                    self = .init(
                        a: from.a ?? self.a,
                        b: from.b ?? self.b,
                        c: from.c ?? self.c,
                        d: from.d ?? self.d
                    )
                }
            
                func spread(from: Self) -> Self {
                    .init(
                        a: from.a ?? self.a,
                        b: from.b ?? self.b,
                        c: from.c ?? self.c,
                        d: from.d ?? self.d
                    )
                }
            }
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
