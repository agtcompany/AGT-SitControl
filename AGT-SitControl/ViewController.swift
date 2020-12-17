//
//  ViewController.swift
//  AGT-SitControl
//
//  Created by Иван Андриянов on 23.11.2020.
//

import Foundation
import UIKit
import CoreBluetooth

var pressedButton = 0
var selectedTableRow = 0
var forTableButtonWidth : CGFloat = 0

let massageNames = ["Программа массажа 1", "Программа массажа 2", "Программа массажа 3", "Программа массажа 4", "Программа массажа 5"]

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

// var tiki = 0

extension UIButton {
    func applyBlueBorder() {
        clipsToBounds = true
        layer.cornerRadius =  frame.size.height / 4
        layer.borderColor = UIColor.blue.cgColor
        layer.borderWidth = 3
    }
    func applyWhiteBorder(_ think : Int) {
        clipsToBounds = true
        layer.cornerRadius =  frame.size.height / 2
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = CGFloat(think)
        setTitleColor(UIColor.white, for: .normal)
        
    }
    func applyWhiteBorder() {
        layer.borderColor = UIColor.white.cgColor
        setTitleColor(UIColor.white, for: .normal)
        
    }
    
}

class ViewController: UIViewController, CBCentralManagerDelegate,
                      CBPeripheralDelegate {
    
    
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    var characteristic: CBCharacteristic?
    
    
    var selectedMassage = 0
    var numberSelectedSit = 0
    var sendNumber = 0
    var valueSend: [UInt8] = []
    var BTConnect = false
    var BTFind = false
    var pressedCB = false
    let BTName = "AGT-SITCONTROL-"
    let BT_SCRATCH_UUID = CBUUID(string: "FFE1")
    let BT_SERVICE_UUID = CBUUID(string: "FFE0")
    
    var sit = Array(repeating: Sit(), count: 8)
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var timeMassageLabel: UILabel!
    
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var replayButton: UIButton!
    

    @IBOutlet var massageProgramButton: UIButton!
    @IBOutlet var selectSitButton: UIButton!
    @IBOutlet var memoryButton: UIButton!
    @IBOutlet var conturButton: [UIButton]!
    @IBOutlet var contursButton: [UIButton]!
    
    
    struct Sit {
        let numberMem = 4
        let numberPads = 11
        
        var enablePad = [Bool]()
        var pressure = [Int]()
        var pressureMem = [[Int]]()
        
        init(){
            for index in 0..<numberMem {
                pressureMem.append([])
                for _ in 0..<numberPads {
                    pressureMem[index].append(0)
                }
            }
            for _ in 0..<numberPads {
                pressure.append(0)
                enablePad.append(false)
            }
        }
    }
    
    
/*
    // Организация функции по таймеру
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            tiki += 1
            print("Таймер! \(tiki)")
        }
*/
    
// Отображаем соответствующее нажатой кнопке всплывающее меню
    @IBAction func selectedButtonTable(_ sender: UIButton) {
        pressedButton = Int(sender.restorationIdentifier!)!
        print("\(pressedButton)")
        func setRedButton(_ offset: Int){
            conturButton[pressedButton-3+offset].layer.borderColor = UIColor.red.cgColor
            conturButton[pressedButton-3+offset].setTitleColor(UIColor.red, for: .normal)
        }
        switch pressedButton {
        case 0: tappedButton(selectSitButton)
        case 1: tappedButton(massageProgramButton)
        case 2: tappedButton(memoryButton)
        case 3...7:
            setRedButton(0)
            setRedButton(11)
            tappedConturButton(conturButton[pressedButton-3])
        case 10...11:
            setRedButton(0)
            setRedButton(9)
            tappedConturButton(conturButton[pressedButton-3])
        case 8...9, 12...13:
            setRedButton(0)
            tappedConturButton(conturButton[pressedButton-3])
        case 14...18:
            setRedButton(0)
            setRedButton(-11)
            tappedConturButton(conturButton[pressedButton-3])
        case 19...20:
            setRedButton(0)
            setRedButton(-9)
            tappedConturButton(conturButton[pressedButton-3])
        case 21:
            setRedButton(-13)
            setRedButton(-12)
            tappedConturButton(contursButton[pressedButton-21])
        case 22:
            setRedButton(-17)
            setRedButton(-12)
            setRedButton(-11)
            setRedButton(-6)
            setRedButton(-3)
            setRedButton(-2)
            tappedConturButton(contursButton[pressedButton-21])
        case 23:
            for index in -20 ... -3 {
                setRedButton(index)
            }
            tappedConturButton(contursButton[pressedButton-21])
        case 24:
            setRedButton(-21)
            setRedButton(-20)
            setRedButton(-18)
            setRedButton(-17)
            setRedButton(-10)
            setRedButton(-9)
            setRedButton(-7)
            setRedButton(-6)
            tappedConturButton(contursButton[pressedButton-21])
        case 25:
            setRedButton(-13)
            setRedButton(-12)
            tappedConturButton(contursButton[pressedButton-21])
        default:
            break
        }
 
    }
    
// Организация всплывающей таблицы выбора программы массажа
/*
    private func setupGestures(){
        
        var tapGesture =  UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGesture.numberOfTapsRequired = 1
        selectSitButton.addGestureRecognizer(tapGesture)
    }
 */
    
    // Вывод всплывающего меню соответствующей кнопки
    func tappedButton(_ button : UIButton!){
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") else { return }
        popVC.modalPresentationStyle = .popover
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = button
        popOverVC?.sourceRect = CGRect(x: button.bounds.midX, y: button.bounds.maxY, width: 0, height: 0)
        forTableButtonWidth = button.bounds.width
        self.present(popVC, animated: true)
    }
    
    func tappedConturButton(_ button : UIButton!){
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") else { return }
        popVC.modalPresentationStyle = .popover
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = memoryButton
        popOverVC?.sourceRect = CGRect(x:  memoryButton.bounds.maxX + 17 , y: memoryButton.bounds.maxY + 200, width: 0, height: 0)
        forTableButtonWidth = 28 //button.bounds.width
        self.present(popVC, animated: true)
    }
    
    // Конфигурация кнопок и меток
    func modButton() {
        
        infoLabel.layer.cornerRadius =   infoLabel.frame.size.height / 4
        infoLabel.layer.borderColor = UIColor.systemGray2.cgColor
        infoLabel.layer.borderWidth = 2
        
        timeMassageLabel.layer.cornerRadius =   timeMassageLabel.frame.size.height / 4
        timeMassageLabel.layer.borderColor = UIColor.systemGray2.cgColor
        timeMassageLabel.layer.borderWidth = 3
        
        playPauseButton.applyBlueBorder()
        stopButton.applyBlueBorder()
        replayButton.applyBlueBorder()
        massageProgramButton.applyBlueBorder()
        selectSitButton.applyBlueBorder()
        memoryButton.applyBlueBorder()
        
 //       playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        stopButton.isEnabled = false
    
        for index in 0...17 { conturButton[index].applyWhiteBorder(1)
        }
        for index in 0...4 { contursButton[index].applyBlueBorder()
        }
        
    }
    

    // func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    // }
    
    // Проверяем на включение блютуза, и если включено, начинаем сканировать
    
    
 // Проверка включен ли Bluetooth. Предупреждение и выход если выключен
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        modButton()
        
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            
            infoLabel.text = "Поиск и установление соединения с сидением \(numberSelectedSit + 1) . . ."
        }
        else {/*
            let alertBTOff = UIAlertController (title: "ВНИМАНИЕ ! Bluetooth выключен !", message: "Для работы приложения необходимо включить в настройках функцию Bluetooth.", preferredStyle: .alert)
            let action = UIAlertAction (title: "OK", style: .default, handler: { _ in exit(0)} )
            alertBTOff.addAction(action)
            present(alertBTOff, animated: true, completion: nil)
 */
        }
    }

    // Находим устройства, подключаемся к нужному и останавливаем сканирование
    func centralManager(
      _ central: CBCentralManager,
      didDiscover peripheral: CBPeripheral,
      advertisementData: [String : Any],
      rssi RSSI: NSNumber) {
        
      let device = (advertisementData as NSDictionary)
        .object(forKey: CBAdvertisementDataLocalNameKey)
        as? NSString
 
      if device?.contains("\(BTName)" + "\(numberSelectedSit)") == true {
            BTFind = true
            self.manager.stopScan()
            self.peripheral = peripheral
            self.peripheral.delegate = self
            manager.connect(peripheral, options: nil)
            infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1)"
            
      }
      else {
       //     BTFind = false
       //     infoBTLabel.text! += "Соединение не установлено \r"
      }
 
    }
    
/*
    @IBAction func selectSit(_ sender: UISegmentedControl) {
  
        numberSelectedSit = sender.selectedSegmentIndex
        reconnectBT()
        for i1 in 0..<sit[numberSelectedSit].numberMem {
            for i2 in 0..<sit[numberSelectedSit].numberPads {
  //              infoBTLabel.text! += (" \(sit[numberSelectedSit].pressureMem[i1][i2] + numberSelectedSit) ")
            }
        }
        
    }
  */
    
    func reconnectBT() {
        if peripheral != nil {
            manager.cancelPeripheralConnection(peripheral)
        }
        manager.scanForPeripherals(withServices: nil, options: nil)
        infoLabel.text = "Поиск и установление соединения с сидением \(numberSelectedSit + 1) . . ."
    }
    
    // Устанавливаем соединение с выбранным переферийным устройством
    func centralManager(
      _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral) {
      peripheral.discoverServices(nil)
      BTConnect = true
      infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1)"
    }
    
    // Разрываем соединение и включаем сканирование переферийных устройств
    func centralManager(
      _ central: CBCentralManager,
        didDisconnectPeripheral
            peripheral: CBPeripheral, error: Error?) {
      
      peripheral.discoverServices(nil)
      BTConnect = false
      central.scanForPeripherals(withServices: nil, options: nil)
      infoLabel.text = "Поиск и установление соединения с сидением \(numberSelectedSit + 1) . . ."
    }

    // Опознаем характеристики переферийного устройства
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?){
    // Пролистываем существующие характеристики, и
    // проверяем обновление данных для нужной характеристики
        
        for characteristic in service.characteristics! {
           let thisCharacteristic = characteristic as CBCharacteristic
           if characteristic.uuid == BT_SCRATCH_UUID {            self.peripheral.setNotifyValue(true, for: thisCharacteristic)
               if !valueSend.isEmpty {
                  let data = NSData(bytes: &valueSend, length: valueSend.count)
        //                                      MemoryLayout<UInt8>.size)
                  peripheral.writeValue(data as Data, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
   //               infoBTLabel.text = "\r 5) Send \(valueSend) "
                  valueSend = []
               }
            }
        }
    }

    
    // Поступление данных с переферийного устройства
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // Проверяем, что это данные с нужного нам UUID
        if characteristic.uuid == BT_SCRATCH_UUID {
            if let charac1 = characteristic.value {
                if let content = String(data: charac1, encoding: String.Encoding.utf8) {
  //                  infoBTLabel.text = "\r 4) \(content) \n \(charac1) \n"
                    var icn = 0
                    for codeUnit in content.utf8 {
                        let st = String(format:"%02X", codeUnit)
  //                      infoBTLabel.text! += "\(st):\(charac1[icn]), "
                        icn += 1
                    }
                    
                }
            }
        }
    }
    
// Отправить данные
    @IBAction func goButton(_ sender: UIButton) {
        if BTConnect {
            valueSend = [44, 45, 76, 43, 12, 134, 212, 32, 127, 34, 123, 124, 123, 123, 123, 43, 231, 212, 212, 212, 123, 43, 142, 36, 76, 65, 45, 65, 56, 76, 98, 78, 67, 56, 87, 56, 87, 56]
            sendNumber += 1
            if sendNumber > 255 { sendNumber = 0 }
            valueSend[0] = UInt8(sendNumber)
            manager.connect(peripheral, options: nil)
        }
    }
   
    
//    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor
//                        characteristic: CBCharacteristic, error: Error?){
//        // characteristic.properties
//        // characteristic.isNotifying {
//        infoBTLabel.text! += "\r 6) Send OK "
//    }
    
 // Получение сервисов от устройства
    func peripheral(
      _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?) {
      for service in peripheral.services! {
        _ = service as CBService

        if service.uuid == BT_SERVICE_UUID {
          peripheral.discoverCharacteristics(nil, for: service)
        }
      }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
 //       setupGestures()
        manager = CBCentralManager(delegate: self, queue: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectAction), name: NSNotification.Name("ChangeBN"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setTextButtonPads), name: NSNotification.Name("ChangeWhite"), object: nil)
    }

    @objc func setTextButtonPads(){
        for index in 0...10 {
                conturButton[index].applyWhiteBorder(sit[numberSelectedSit].pressure[index]+1)
                conturButton[index].setTitle("\(sit[numberSelectedSit].pressure[index])", for: .normal)
        }
        for index in 11...15 {
                conturButton[index].applyWhiteBorder(sit[numberSelectedSit].pressure[index-11]+1)
                conturButton[index].setTitle("\(sit[numberSelectedSit].pressure[index-11])", for: .normal)
        }
        for index in 16...17 {
                conturButton[index].applyWhiteBorder(sit[numberSelectedSit].pressure[index-9]+1)
                conturButton[index].setTitle("\(sit[numberSelectedSit].pressure[index-9])", for: .normal)
        }
    }
    
    
    @objc func selectAction(){
        switch pressedButton {
        case 0:
            selectSitButton.setTitle("Массажное сидение \(selectedTableRow + 1)", for: .normal)
            numberSelectedSit = selectedTableRow
            reconnectBT()
        case 1:
            massageProgramButton.setTitle(massageNames[selectedTableRow], for: .normal)
        case 2:
            switch selectedTableRow {
            case 0...2:
                if sit[numberSelectedSit].pressure != sit[numberSelectedSit].pressureMem[selectedTableRow] {
                    sit[numberSelectedSit].pressureMem[3] = sit[numberSelectedSit].pressure
                    sit[numberSelectedSit].pressure = sit[numberSelectedSit].pressureMem[selectedTableRow]
                }
                setTextButtonPads()
            case 3...5:
                sit[numberSelectedSit].pressureMem[selectedTableRow-3] = sit[numberSelectedSit].pressure
            case 6:
                if sit[numberSelectedSit].pressureMem[3] != sit[numberSelectedSit].pressure {
                   sit[numberSelectedSit].pressure = sit[numberSelectedSit].pressureMem[3]
                }
                setTextButtonPads()
            default:
                break
            }
        case 3...13:
            sit[numberSelectedSit].pressure[pressedButton-3] = selectedTableRow
            setTextButtonPads()
        case 14...18:
            sit[numberSelectedSit].pressure[pressedButton-3-11] = selectedTableRow
            setTextButtonPads()
        case 19...20:
            sit[numberSelectedSit].pressure[pressedButton-3-9] = selectedTableRow
            setTextButtonPads()
        case 21:
            sit[numberSelectedSit].pressure[pressedButton-3-13] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-12] = selectedTableRow
            setTextButtonPads()
        case 22:
            sit[numberSelectedSit].pressure[pressedButton-3-17] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-12] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-11] = selectedTableRow
            setTextButtonPads()
        case 23:
            for index in 0...10 {
                sit[numberSelectedSit].pressure[index] = selectedTableRow
            }
            setTextButtonPads()
         case 24:
            sit[numberSelectedSit].pressure[pressedButton-3-21] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-20] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-18] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-17] = selectedTableRow
            setTextButtonPads()
        case 25:
            sit[numberSelectedSit].pressure[pressedButton-3-13] = selectedTableRow
            sit[numberSelectedSit].pressure[pressedButton-3-12] = selectedTableRow
            setTextButtonPads()
        default:
            break
        }
    }
    
    
    
}

