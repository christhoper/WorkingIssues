//
//  Strategy.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/12.
//

import Foundation

//MARK: - 策略模式： Strategy

/*
 对象有某个行为，但是在不同的场景中，该行为有不同的实现算法。
 策略模式：
 - 定义了一族算法（业务规则）；
 - 封装了每个算法；
 - 这族的算法可互换代替（interChangeable）
 */


struct TestSubject {
    
    let pupilDiameter: Double
    let blushResponse: Double
    let isOrganic: Bool
}

protocol RealnessTesting: AnyObject {
    
    func testRealness(_ testSubject: TestSubject) -> Bool
}

final class VoightKampffTest: RealnessTesting {
    
    func testRealness(_ testSubject: TestSubject) -> Bool {
        return testSubject.pupilDiameter < 30 || testSubject.blushResponse == 0.0
    }
}


final class GeneticTest: RealnessTesting {
    
    func testRealness(_ testSubject: TestSubject) -> Bool {
        return testSubject.isOrganic
    }
}


final class BladeRunner {
    
    private let strategy: RealnessTesting
    init(test: RealnessTesting) {
        self.strategy = test
    }
    
    func testIfAndroid(_ testSubject: TestSubject) -> Bool {
        return !strategy.testRealness(testSubject)
    }
}
