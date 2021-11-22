//
//  Interpreter.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 解释器: Interpreter
/*
 给定一种于洋，定义他的文法的一种表示，并定义一个解释器，该解释器使用该表示来解释语言中句子
 */

/// 解释器协议
protocol IntegerExpression {
    
    func evaluate(_ context: IntegerContext) -> Int
    func replace(character name: Character, integerExtenssion: IntegerExpression) -> IntegerExpression
    func copied() -> IntegerExpression
}

final class IntegerContext {
    
    private var data: [Character: Int] = [:]
    
    func lookup(name: Character) -> Int {
        return self.data[name]!
    }
    
    func assign(expression: IntegerVariableExpression, value: Int) {
        self.data[expression.name] = value
    }
    
}

final class IntegerVariableExpression: IntegerExpression {
    
    let name: Character
    init(name: Character) {
        self.name = name
    }
    
    func evaluate(_ context: IntegerContext) -> Int {
        return context.lookup(name: self.name)
    }
    
    func replace(character name: Character, integerExtenssion: IntegerExpression) -> IntegerExpression {
        if name == self.name {
            return integerExtenssion.copied()
        } else {
            return IntegerVariableExpression(name: self.name)
        }
    }
    
    func copied() -> IntegerExpression {
        return IntegerVariableExpression(name: self.name)
    }
}

final class AddExpression: IntegerExpression {
    
    private var operand1: IntegerExpression
    private var operand2: IntegerExpression
    
    init(op1: IntegerExpression, op2: IntegerExpression) {
        self.operand1 = op1
        self.operand2 = op2
    }
    
    func evaluate(_ context: IntegerContext) -> Int {
        return self.operand1.evaluate(context) + self.operand2.evaluate(context)
    }
    
    func replace(character name: Character, integerExtenssion: IntegerExpression) -> IntegerExpression {
        return AddExpression(op1: operand1.replace(character: name, integerExtenssion: integerExtenssion), op2: operand2.replace(character: name, integerExtenssion: integerExtenssion))
    }
    
    func copied() -> IntegerExpression {
        return AddExpression(op1: self.operand1, op2: self.operand2)
    }
}


class IntereterTest {
    init() {}
    
    func test() {
        let context = IntegerContext()
        let a = IntegerVariableExpression(name: "A")
        let b = IntegerVariableExpression(name: "B")
        let c = IntegerVariableExpression(name: "C")
        
        let expression = AddExpression(op1: a, op2: AddExpression(op1: b, op2: c))
        context.assign(expression: a, value: 2)
        context.assign(expression: b, value: 1)
        context.assign(expression: c, value: 3)
        let result = expression.evaluate(context)
        print("解释器结果：\(result)")
    }
    
}
