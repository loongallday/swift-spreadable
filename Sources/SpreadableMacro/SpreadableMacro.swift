import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct SpreadableMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage(
                "Spreading is only applicable on struct."
            )
        }
        let members = try extractStructMemberNames(from: structDecl)
        let isPublic = structDecl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.public) })
        let memberAccessExpressions = members.map { memberName in
            LabeledExprSyntax(
                leadingTrivia: memberName == members.first ? .newline : nil,
                label: .identifier(memberName),
                colon: .colonToken(),
                expression: SequenceExprSyntax(
                    elements: .init(
                        itemsBuilder: {
                            MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(
                                    baseName: .identifier("from")
                                ),
                                period: .periodToken(),
                                declName: .init(
                                    baseName: .identifier(memberName)
                                )
                            )
                            BinaryOperatorExprSyntax(operator: .binaryOperator("??"))
                            MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(
                                    baseName: .keyword(.self)
                                ),
                                period: .periodToken(),
                                declName: .init(
                                    baseName: .identifier(memberName)
                                )
                            )
                        }
                    )
                ),
                trailingComma: memberName == members.last ? nil : .commaToken(),
                trailingTrivia: .newline
            )
        }
        
        return [
            ExtensionDeclSyntax(
                modifiers: isPublic ? [.init(name: .keyword(.public))] : [],
                extendedType: IdentifierTypeSyntax(name: .identifier(structDecl.name.text)),
                inheritanceClause: nil,
                memberBlock: .init(
                    members: .init(
                        itemsBuilder: {
                            DeclSyntax(spreadFunction(memberAccessExpressions))
                            DeclSyntax(mutatingSpreadFunction(memberAccessExpressions))
                        }
                    )
                )
            )
        ]
    }
    
    static func spreadFunction(
        _ memberAccessExpressions: [LabeledExprSyntax]
    ) -> FunctionDeclSyntax {
        FunctionDeclSyntax(
            attributes: [],
            modifiers: [],
            funcKeyword: .keyword(.func),
            name: .identifier("spread"),
            signature: .init(
                parameterClause: .init(
                    leftParen: .leftParenToken(),
                    parameters: FunctionParameterListSyntax(
                        itemsBuilder: {
                            FunctionParameterSyntax(
                                firstName: .identifier("from"),
                                type: IdentifierTypeSyntax(name: .keyword(.Self))
                            )
                        }
                    )
                ),
                returnClause: .init(
                    arrow: .arrowToken(),
                    type: IdentifierTypeSyntax(name: .keyword(.Self))
                )
            ),
            body: .init(
                leftBrace: .leftBraceToken(),
                statements: CodeBlockItemListSyntax(
                    itemsBuilder: {
                        CodeBlockItemSyntax(
                            item: .expr(
                                .init(
                                    FunctionCallExprSyntax(
                                        calledExpression: MemberAccessExprSyntax(
                                            period: .periodToken(),
                                            declName: DeclReferenceExprSyntax(
                                                baseName: .keyword(SwiftSyntax.Keyword.`init`)
                                            )
                                        ),
                                        leftParen: .leftParenToken(),
                                        arguments: .init(memberAccessExpressions),
                                        rightParen: .rightParenToken()
                                    )
                                )
                            )
                        )
                    }
                )
            ),
            trailingTrivia: .newline
        )
    }
    
    static func mutatingSpreadFunction(
        _ memberAccessExpressions: [LabeledExprSyntax]
    ) -> FunctionDeclSyntax {
        FunctionDeclSyntax(
            attributes: [],
            modifiers: [DeclModifierSyntax(name: .keyword(.mutating))],
            funcKeyword: .keyword(.func),
            name: .identifier("mutatingSpread"),
            signature: .init(
                parameterClause: .init(
                    leftParen: .leftParenToken(),
                    parameters: FunctionParameterListSyntax(
                        itemsBuilder: {
                            FunctionParameterSyntax(
                                firstName: .identifier("from"),
                                type: IdentifierTypeSyntax(name: .keyword(.Self))
                            )
                        }
                    )
                )
            ),
            body: .init(
                leftBrace: .leftBraceToken(),
                statements: CodeBlockItemListSyntax(
                    itemsBuilder: {
                        CodeBlockItemSyntax(
                            item: .expr(
                                .init(
                                    SequenceExprSyntax(
                                        elementsBuilder: {
                                            DeclReferenceExprSyntax(
                                                baseName: .keyword(.`self`)
                                            )
                                            AssignmentExprSyntax(
                                                equal: .equalToken()
                                            )
                                            FunctionCallExprSyntax(
                                                calledExpression: MemberAccessExprSyntax(
                                                    period: .periodToken(),
                                                    declName: DeclReferenceExprSyntax(
                                                        baseName: .keyword(SwiftSyntax.Keyword.`init`)
                                                    )
                                                ),
                                                leftParen: .leftParenToken(),
                                                arguments: .init(memberAccessExpressions),
                                                rightParen: .rightParenToken()
                                            )
                                        }
                                    )
                                )
                            )
                        )
                    }
                )
            )
        )
    }
    
    static func extractStructMemberNames(
        from structDecl: StructDeclSyntax
    ) throws -> [String] {
        var memberNames: [String] = []
        
        for member in structDecl.memberBlock.members {
            if let variableDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in variableDecl.bindings {
                    if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
                       let _ = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) {
                        let name = identifierPattern.identifier.text
                        memberNames.append(name)
                    } else {
                        throw MacroExpansionErrorMessage(
                            "All members must be optional for spreading. Found a non-optional member in \(structDecl.name.text)."
                        )
                    }
                }
            }
        }
        
        return memberNames
    }
}

@main
struct swift_spreadablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SpreadableMacro.self
    ]
}
