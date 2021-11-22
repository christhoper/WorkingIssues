//
//  ViewController.swift
//  WorkingIssues
//
//  Created by bailun on 2021/2/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chainOfResponsibilityTest()
        commandtest()
        interpreterTest()
        iteratorTest()
        mediatorTest()
        mementoTest()
        observerTest()
        stateTest()
        strategyTest()
        visitorTest()
    }

    func chainOfResponsibilityTest() {
        let cls = MoneyTest()
        cls.testMoney()
    }
    
    func commandtest() {
        let play = "DoorOPeration"
        let doorAction = DoorOperation(doors: play)
        let command1 = doorAction.openDoor()
        let command2 = doorAction.closeDoor()
        print(command1, command2)
    }
    
    func interpreterTest() {
        let inter = IntereterTest()
        inter.test()
    }
    
    func iteratorTest() {
        let iterator = IteratorTest()
        iterator.test()
    }

    func mediatorTest() {
        let mediator = MediatorTest()
        mediator.test()
    }
    
    func mementoTest() {
        let memnto = MementoTest()
        memnto.test()
    }
    
    func observerTest() {
        let observer = Observer()
        let testChamber = TestChambers()
        testChamber.observer = observer
        testChamber.testChambersNumber = 1
    }
    
    
    func stateTest() {
        let userContext = Context()
        userContext.changeStateToAuthorized(userId: "hend")
        print("当前login", userContext.userId as Any, userContext.isAuthorized)
        userContext.changeStateToUnAuthorized()
        print("相当于取消了login", userContext.userId as Any, userContext.isAuthorized)
    }
    
    func strategyTest() {
        let rachel = TestSubject(pupilDiameter: 30.3, blushResponse: 0.0, isOrganic: false)
        let deckard = BladeRunner(test: VoightKampffTest())
        let isRachelAndroid = deckard.testIfAndroid(rachel)
        print("isRachelAndroid", isRachelAndroid)
        let gaff = BladeRunner(test: GeneticTest())
        let gaffAndroid = gaff.testIfAndroid(rachel)
        print("gaffAndroid", gaffAndroid)
    }
    
    func visitorTest() {
        let planets: [Planet] = [PlanetAlderan(), PlanetTatoonie(), PlanetCoruscant(), MoonJedda()]
        let names = planets.map { planet -> String in
            let visitor = NameVisitor()
            planet.accept(visitor: visitor)
            return visitor.name
        }
        
        print("访问者", names)
    }
}

