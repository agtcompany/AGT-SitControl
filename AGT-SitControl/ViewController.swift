//
//  ViewController.swift
//  AGT-SitControl
//
//  Created by Иван Андриянов on 23.11.2020.
//

import Foundation
import UIKit
import CoreBluetooth


let massageNames = ["Программа массажа 1", "Программа массажа 2", "Программа массажа 3", "Программа массажа 4", "Программа массажа 5"]
var massageProgramButtonWidth : CGFloat = 0
var massageProgramButtonRow = 0

extension ViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}


// var tiki = 0

class ViewController: UIViewController, CBCentralManagerDelegate,
                      CBPeripheralDelegate {
    
/*
// Организация функции по таймеру
    let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
        tiki += 1
        print("Таймер! \(tiki)")
    }
 */
    
    struct Sit {
        let numberMem = 3
        let numberPads = 9
        
        var pressure = [Int]()
        var pressureMem = [[Int]]()
        
        init(){
            for index in 0..<numberMem {
                pressureMem.append([])
                for _ in 0..<numberPads {
                    pressureMem[index].append(0)
                }
            }
            
        }
    }
// Организация всплывающей таблицы выбора программы массажа
    private func setupGestures(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGesture.numberOfTapsRequired = 1
        massageProgramButton.addGestureRecognizer(tapGesture)
    }
    @objc
    private func tapped() {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") else { return }
        popVC.modalPresentationStyle = .popover
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = self.massageProgramButton
        popOverVC?.sourceRect = CGRect(x: self.massageProgramButton.bounds.midX, y: self.massageProgramButton.bounds.maxY, width: 0, height: 0)
        massageProgramButtonWidth = self.massageProgramButton.bounds.width
        popVC.preferredContentSize = CGSize(width: self.massageProgramButton.bounds.width, height: 250)
         
        self.present(popVC, animated: true)
    }
    
    
    
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
    let BTName = "AGT-SitContol-"
    let BT_SCRATCH_UUID = CBUUID(string: "FFE1")
    let BT_SERVICE_UUID = CBUUID(string: "FFE0")
    
    var sit = Array(repeating: Sit(), count: 8)
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var infoBTLabel: UILabel!
    
    @IBOutlet var goButtonLabel: UIButton!
    @IBOutlet var disconnectButtonLabel: UIButton!
    @IBOutlet var connectButtonLabel: UIButton!

    @IBOutlet weak var massageProgramButton: UIButton!
    
   
    
    func modButton() {
        infoLabel.layer.borderColor = UIColor.systemGray2.cgColor
        infoLabel.layer.borderWidth = 1

        goButtonLabel.layer.cornerRadius =   goButtonLabel.frame.size.height / 4
        goButtonLabel.layer.borderColor = UIColor.blue.cgColor
        goButtonLabel.layer.borderWidth = 3
        goButtonLabel.setTitle("Send", for: .normal)
        goButtonLabel.isEnabled = false
        goButtonLabel.setTitleColor(UIColor.black, for: UIControl.State.disabled)
        goButtonLabel.clipsToBounds = true
        
        disconnectButtonLabel.layer.cornerRadius =  disconnectButtonLabel.frame.size.height / 4
        disconnectButtonLabel.layer.borderColor = UIColor.blue.cgColor
        disconnectButtonLabel.layer.borderWidth = 3
        disconnectButtonLabel.clipsToBounds = true

        connectButtonLabel.layer.cornerRadius =  connectButtonLabel.frame.size.height / 4
        connectButtonLabel.layer.borderColor = UIColor.blue.cgColor
        connectButtonLabel.layer.borderWidth = 3
        connectButtonLabel.clipsToBounds = true
    
        massageProgramButton.layer.cornerRadius =  massageProgramButton.frame.size.height / 4
        massageProgramButton.layer.borderColor = UIColor.blue.cgColor
        massageProgramButton.layer.borderWidth = 3
        
        
    }
    

    // func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    // }
    
    // Проверяем на включение блютуза, и если включено, начинаем сканировать
    
    
 // Проверка включен ли Bluetooth. Предупреждение и выход если выключен
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        modButton()
        
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            
            infoBTLabel.text = "BT turn ON. Searching...\n"
        }
        else {
            let alertBTOff = UIAlertController (title: "ВНИМАНИЕ ! Bluetooth выключен !", message: "Для работы приложения необходимо включить в настройках функцию Bluetooth.", preferredStyle: .alert)
            let action = UIAlertAction (title: "OK", style: .default, handler: { _ in exit(0)} )
            alertBTOff.addAction(action)
            present(alertBTOff, animated: true, completion: nil)
 
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
    //        infoBTLabel.text! += "\(peripheral.name!) найдено RSSI = \(RSSI) дБ. Установить?"
            self.manager.stopScan()
            self.peripheral = peripheral
            self.peripheral.delegate = self
            if pressedCB {
              manager.connect(peripheral, options: nil)
              pressedCB = false
              goButtonLabel.isEnabled = true
            }
      }
      else {
        
      //      BTFind = false
       //     infoBTLabel.text! += "Соединение не установлено \r"
      }
 
    }
    
    
    @IBAction func selectSit(_ sender: UISegmentedControl) {
  
    //    infoBTLabel.text = (" \(sender.selectedSegmentIndex) ")
        numberSelectedSit = sender.selectedSegmentIndex
        
        for i1 in 0..<sit[numberSelectedSit].numberMem {
            for i2 in 0..<sit[numberSelectedSit].numberPads {
                infoBTLabel.text! += (" \(sit[numberSelectedSit].pressureMem[i1][i2] + numberSelectedSit) ")
            }
        }
        
    }
    
 //  Разорвать соединение, включить поиск, и если найдено, соединить
    @IBAction func control1Button(_ sender: UIButton) {
        pressedCB = true
        reconnectBT()
        
    }
    
 // Разорвать соединение, и включить поиск
    @IBAction func control2Button(_ sender: UIButton) {
        pressedCB = false
        reconnectBT()
    }
    
    func reconnectBT() {
        if peripheral != nil {
            manager.cancelPeripheralConnection(peripheral)
        }
        manager.scanForPeripherals(withServices: nil, options: nil)
        infoBTLabel.text = "BT turn ON. Searching...\n"
        goButtonLabel.isEnabled = false
    }
    
    // Устанавливаем соединение с выбранным переферийным устройством
    func centralManager(
      _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral) {
      peripheral.discoverServices(nil)
      BTConnect = true
      infoBTLabel.text! += "\rСоединение установлено !"
    }
    
    // Разрываем соединение и включаем сканирование переферийных устройств
    func centralManager(
      _ central: CBCentralManager,
        didDisconnectPeripheral
            peripheral: CBPeripheral, error: Error?) {
      
      peripheral.discoverServices(nil)
      BTConnect = false
      central.scanForPeripherals(withServices: nil, options: nil)
      infoBTLabel.text = "Соединение разорвано !\nBT turn ON. Searching...\n"
      goButtonLabel.isEnabled = false
        
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
                  infoBTLabel.text = "\r 5) Send \(valueSend) "
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
                    infoBTLabel.text = "\r 4) \(content) \n \(charac1) \n"
                    var icn = 0
                    for codeUnit in content.utf8 {
                        let st = String(format:"%02X", codeUnit)
                        infoBTLabel.text! += "\(st):\(charac1[icn]), "
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

        infoBTLabel.text! += "\r 1) \(service.uuid)"

        if service.uuid == BT_SERVICE_UUID {
          peripheral.discoverCharacteristics(nil, for: service)
          infoBTLabel.text! += "\r 2) \(peripheral.services!)"
        }
      }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
        manager = CBCentralManager(delegate: self, queue: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(changeNameProgramMassage), name: NSNotification.Name("ChangeNPM"), object: nil)
            
    }

    @objc func changeNameProgramMassage(){
        massageProgramButton.setTitle(massageNames[massageProgramButtonRow], for: .normal)
        
    }
    
    
}

