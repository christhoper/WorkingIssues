//
//  DesignDemolViewController.swift
//  WorkingIssues
//
//  Created by bailun on 2021/12/22.
//

import UIKit

class DesignDemolViewController: UIViewController {
    
    var behaviorals: [String] {
        return ["责任链: Chain Of Responsibility",
                "命令: Command",
                "解释器: Interpreter",
                "迭代器: Iterator",
                "中介者: Mediator",
                "备忘录: Memento",
                "观察者: Observer",
                "状态模式: State",
                "策略模式: Strategy",
                "访问者模式: Visitor"]
    }
    
    var creationals: [String] {
        return ["抽象工厂: Abstract Factory",
                "生成器: Builder",
                "工厂方法: Factory Method",
                "原型: Prototype",
                "单态: Monostate",
                "单利: Singleton"]
    }
    
    var structurals: [String] {
        return ["适配器: Adapter",
                "桥接: Bridge",
                "组合: Composite",
                "修饰: Decorator",
                "外观: Facade",
                "享元: Flyweight",
                "保护代理模式: Protection Proxy",
                "虚拟代理模式: Virtual Proxy"]
    }
    
    var dataSource: [[String]] {
        return [behaviorals, creationals, structurals]
    }
    
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.frame, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellIdentifier")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(tableView)
        // Do any additional setup after loading the view.
        behaviorTest()
        creationTest()
        structuralTest()
    }
}

//MARK: - 行为型
extension DesignDemolViewController {
    
    func behaviorTest() {
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

//MARK: - 创建型
extension DesignDemolViewController {
    
    func creationTest() {
        factoryTest()
        builderTest()
        factoryMethodTest()
        monostateTest()
        prototypeTest()
    }
    
    func factoryTest() {
        let big = BurgerFactoryType.big.make()
        let sub = BurgerFactoryType.sub.make()
        
        print("工厂模式", big, sub)
    }
    
    func builderTest() {
        let empire = DeathStarBuilder { builder in
            builder.x = 1
            builder.y = 2
            builder.z = 3
        }
        
        let deathStar = DeathStar(builder: empire)
        
        print("生成器", deathStar?.description as Any)
    }
    
    func factoryMethodTest() {
        let china: String = CurrencyFactory.currency(for: .china)?.code ?? ""
        let japan: String = CurrencyFactory.currency(for: .japan)?.code ?? ""
        let unknow: String = CurrencyFactory.currency(for: .unowned)?.code ?? ""
        
        print("工厂方法",china, japan, unknow)
    }
    
    func monostateTest() {
        // 改变主题
        let setting = Setting() // 默认旧的
        setting.currentTheme = .new // 改变成新的
        
        // 界面1
        let screenColor: UIColor = Setting().currentTheme == .old ? .white : .cyan
        
        // 界面2
        let screenTitle: String = Setting().currentTheme == .old ? "oldTitle" : "newTitle"
        
        print("单态模式", screenColor, screenTitle)
    }
    
    
    func prototypeTest() {
        let prototype = MoonWorker(name: "hend")
        let son = prototype.clone()
        son.health = 30
        
        print("原型模式", prototype.health, son.health)
    }
}


//MARK: - 结构型
extension DesignDemolViewController {
    
    func structuralTest() {
        adapterTest()
        bridgeTest()
        compositeTest()
        decoratorTest()
        facadeTest()
        flyweightTest()
        protectionTest()
        virtualTest()
    }
    
    func adapterTest() {
        let old = OldDeathStarSuperlaserTarget(horizontal: 10.0, vertical: 20.0)
        let new = NewDeathStarlaserTarget(old)
        print("适配器", new.angleHor, new.angleVer)
    }
    
    func bridgeTest() {
        let tv = RemoteControl(appliance: TV())
        tv.turnOn()
        
        let voidce = RemoteControl(appliance: Voidce())
        voidce.turnOn()
        print("桥接模式", tv, voidce)
    }
    
    func compositeTest() {
        let whiteboard = Drawboard(Square(), Circle())
        whiteboard.draw(fillColor: "都是用红色")
        print("组合模式", whiteboard)
    }
    
    func decoratorTest() {
        print("修饰模式")
        var coffee: BeverageDataHaving = SimpleCoffee()
        print("价格: \(coffee.cost), 配方: \(coffee.ingredients)")
        coffee = Milk(beverage: coffee)
        print("价格: \(coffee.cost), 配方: \(coffee.ingredients)")
        coffee = WhipCoffee(beverage: coffee)
        print("价格: \(coffee.cost), 配方: \(coffee.ingredients)")
    }
    
    func facadeTest() {
        let userDefault = Defaults()
        userDefault["store"] = "存储"
        print("外观模式", userDefault["store"])
    }
    
    func flyweightTest() {
        let coffeeShop = CoffeeShop(menu: Menu())
        coffeeShop.takeOrder(origin: "香草", table: 1)
        coffeeShop.takeOrder(origin: "美式", table: 3)
        coffeeShop.serve()
        
        print("享元模式")
    }
    
    func protectionTest() {
        let computer = CurrentComputer()
        let doorName = "hendy"
        let name = computer.open(doors: doorName)
        let canOpen = computer.authenticate(password: "pass")
        let name1 = computer.open(doors: doorName)
        
        print("保护代理模式", name, canOpen, name1)
    }
    
    func virtualTest() {
        let humanInterface = HEVSuitHumanInterface()
        let content = humanInterface.administerMorphine()
        print("虚拟代理模式", content)
    }
}

extension DesignDemolViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath)
        let text = dataSource[indexPath.section][indexPath.row]
        cell.textLabel?.text = text
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let titleLabel = UILabel()
        var title: String = ""
        switch section {
        case 0:
            title = "行为型设计模式"
        case 1:
            title = "创建型设计模式"
        default:
            title = "结构型设计模式"
        }
        titleLabel.text = title
        titleLabel.textColor = .cyan
        return titleLabel
    }
}
