//
//  ViewController.swift
//  AGT-SitControl
//
//  Created by Иван Андриянов on 23.11.2020.
//

import Foundation
import UIKit
import CoreBluetooth

var pressedButton = 0 // ID нажатой кнопки
var selectedTableRow = 0 // Выбранная строка всплыв.меню 0...
var forTableButtonWidth : CGFloat = 0 // Ширина кнопки для всплыв.меню
var numberKlapan = 0 // Клапан управления 0...15


let massageNames = ["Верхний массаж спины (2:27)", "Нижний массаж спины (2:27)", "Массаж поясницы (1:37)", "Массаж сидения (1:37)", "Массаж спины (6:29)", "Массаж спины и поясницы (8:58)", "Общий массаж (10:46)", ]

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
    func applyRedBorder() {
        clipsToBounds = true
        layer.cornerRadius =  frame.size.height / 4
        layer.borderColor = UIColor.red.cgColor
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
 
    func applyAtributeButton(_ color : String, _ think : Int) {
        clipsToBounds = true
        layer.cornerRadius =  frame.size.height / 2
        switch color {
        case "white" :
            layer.borderColor = UIColor.white.cgColor
            setTitleColor(UIColor.white, for: .normal)
        case "black" :
            layer.borderColor = UIColor.black.cgColor
            setTitleColor(UIColor.black, for: .normal)
        case "red" :
            layer.borderColor = UIColor.red.cgColor
            setTitleColor(UIColor.red, for: .normal)
        case "yellow" :
            layer.borderColor = UIColor.yellow.cgColor
            setTitleColor(UIColor.yellow, for: .normal)
        case "gray" :
            layer.borderColor = UIColor.gray.cgColor
            setTitleColor(UIColor.gray, for: .normal)
        default:
            layer.borderColor = UIColor.white.cgColor
            setTitleColor(UIColor.white, for: .normal)
        }
        layer.borderWidth = CGFloat(think)
    }

}

class ViewController: UIViewController, CBCentralManagerDelegate,
                      CBPeripheralDelegate {
    
    let defaults = UserDefaults.standard
    var manager:CBCentralManager!
    var peripheral:CBPeripheral!
    var characteristic: CBCharacteristic?
    var charSend: CBCharacteristic?
    
    var selectContursCount = 0 // Счетчик нажатий для установки доступ. конт.
    var enableSelectConturs = false // Режим определения доступных контуров
    var infoMode = false // Режим справки
    var selectedMassage = 0 // Программа массажа
    var numberSelectedSit = 0 // Номер выбранного сидения 0-7
    var heatLevel : UInt8 = 0 // Уровень обогрева
    var ventLevel : UInt8 = 0 // Уровень вентиляции
    
    var reciveData : [UInt8] = []
    var transmitPressure : [UInt8] = [0,0,0,0,0,0,0,0,0,0,0] // Давления в контурах для передачи
    var pressureConturs : [UInt8] = [0,0,0,0,0,0,0,0,0,0,0] // Давления в контурах по приему
    var enablePad : [UInt8] = [0,0]
    var enablePadSelect : [UInt8] = [0,0]
    
    var setPad : [UInt8] = [0,0]
    var workPad : [UInt8] = [0,0]
    
    
    var pressure : UInt8 = 0 // Текущее давление в блоке
    var temperature : UInt8 = 0 // Текущая температура в блоке
    var massageRun = false // Работа массажа
    var massagePause = false // Включена пауза работы массажа
    var massageRep = false // Включен повтор работы программы массажа
    var pressureWork = false // Идет процесс установки давлений
    var alarmStop = false // Аварийная остановка работы блока
    
    var codeError = 0 // Код ошибки
    var conturError = 0 // Контур ошибки
    let textError = ["Перегрев блока управления.", "Не нагнетается давление. Неисправен компрессор или утечка воздуха в системе.", "Превышено допустимое давление в системе.", "Неисправен датчик давления.", "Неисправен датчик температуры", "Не спускается давление в контуре. Возможно неисправен клапан спуска.", "Слишком долгая установка давления. Возможно утечка воздуха в системе"]
    let textConturError = ["Контур спины 1-й ряд.", "Контур спины 2-й ряд.",  "Контур плечевой боковой поддержки", "Контур спины 3-й ряд.", "Контур спины 4-й ряд.", "Контур верхней поясничной подушки.", "Контур нижней поясничной подушки.", "Контур боковой поддержки спины.", "Контур боковой поддержки сидения.", "Контур задней подушки сидения.", "Контур передней подушки сидения.", "Контур не определен.", ]
                           
    var errorFlags = [false, false, false, false, false, false, false,] // Ошибки
    
    var massageSeconds : UInt8 = 0
    var massageMinuts : UInt8 = 0
    
    var timerBlink  = false // Для мигания по таймеру
    
    var valueSend: [UInt8] = [] // Массив передачи данных по BT
  
    var BTConnect = false
    let BTName = "AGT-SITCONTROL-"
    let BT_SCRATCH_UUID = CBUUID(string: "FFE1")
    let BT_SERVICE_UUID = CBUUID(string: "FFE0")

    struct Sit:Codable {
        var numberMem = 4 // кол-во ячеек памяти настроек 0...
        var numberPads = 11 // кол-во контуров подушек
        
        var pressureMem = [[UInt8]]() // Давления в контурах для каждой ячейки памяти
                
        init(){
            for index in 0..<numberMem {
                pressureMem.append([])
                for _ in 0..<numberPads {
                    pressureMem[index].append(0)
                }
            }
            
        }
    }
    

    // Определение экземпляров сидений. Считывание и запись данных для хранения в смартфоне
    var sit:[Sit]{
        get {
            if let data = defaults.value(forKey: "data") as? Data{
                return try!  PropertyListDecoder().decode([Sit].self,from: data)
            }else{
                return [Sit]()
            }
        }
        set {
            if let data = try? PropertyListEncoder().encode(newValue){
            defaults.set(data, forKey: "data")
            }
        }
    }
  

    
//    sit = Array(repeating: Sit(), count: 8)

    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var timeMassageLabel: UILabel!
    
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var stopButton: UIButton!
    @IBOutlet var replayButton: UIButton!
    

    @IBOutlet var massageProgramButton: UIButton!
    @IBOutlet var selectSitButton: UIButton!
    @IBOutlet var conturButton: [UIButton]!
    @IBOutlet var contursButton: [UIButton]!
    
    @IBOutlet weak var readMemoryButton: UIButton!
    @IBOutlet weak var saveMemoryButton: UIButton!
    @IBOutlet weak var returnMemoryButton: UIButton!
    @IBOutlet weak var renewButton: UIButton!
    
    
    @IBOutlet weak var heatButton: UIButton!
    @IBOutlet weak var ventButton: UIButton!
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var pressLabel: UILabel!
    
    
    @IBOutlet weak var infoButtonLabel: UIButton!
    

    @IBAction func playButton() {
        if infoMode { infoPresent(3) }
        else if BTConnect {
            if enableSelectConturs {
                valueSend = [0,0,0]
                valueSend[0] = 1
                valueSend[1] = enablePadSelect[0]
                valueSend[2] = enablePadSelect[1]
                sendData()
                enableSelectConturs = false
                BTConnectInit()
            }
            else {
                valueSend = []
                if massageRun && !massagePause {
                    valueSend = [4]
                    sendData()
                }
                else if massageRun && massagePause {
                    valueSend = [5]
                    sendData()
                }
                else {
                    for index in 0...MassageData().massagePrograms[selectedMassage].count-1 {
                        valueSend.append(MassageData().massagePrograms[selectedMassage][index])
                        if valueSend.count == 100 {
                            sendData()
                        }
                    }
                    sendData()
                }
            }
        }
    }
    
    func crc(){  // Вычисление CRC8
        let data : [UInt8] = [0x01, 0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
//        let data : [UInt8] = [0x92, 0x01, 0x4B, 0x46, 0x7F, 0xFF, 0x0C, 0x10]
//        let data : [UInt8] = [0x01, 0x00, 0x00, 0x0B, 0x00, 0x39, 0x00, 0x3B, 0x43, 0x01]

        var crc8 : UInt8 = 0xFF
        for i in 0...(data.count - 1) {
            
            crc8 ^= data[i]
            for _ in  0...7 {
                crc8 = (crc8 & 0x80) != 0 ? (crc8 << 1) ^ 0x31 : crc8 << 1
            }
  
        }
        print("crc8 = \(String(format:"%02X", (crc8)))")
    }
    
    @IBAction func stopButtonAction() {
   //     crc()
        if infoMode { infoPresent(4) }
        else if enableSelectConturs {
            enableSelectConturs = false
            BTConnectInit()
        }
        else if BTConnect {
            valueSend = [6]
            sendData()
        }
    }
    
    @IBAction func replayButtonAction() {
        if infoMode { infoPresent(5) }
        else if BTConnect {
            if massageRep { valueSend = [10] }
            else { valueSend = [9] }
            sendData()
        }
    }
    
    @IBAction func returnMemoryButtonAction(_ sender: UIButton) {
        if infoMode { infoPresent(8) }
        else if sit[numberSelectedSit].pressureMem[3] != pressureConturs {
            transmitPressure = sit[numberSelectedSit].pressureMem[3]
            setPad = [0,0]
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        }
    }
    
    @IBAction func renewButtonAction(_ sender: UIButton) {
        if infoMode { infoPresent(9) }
        else if BTConnect {
            setPad = [0,0]
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        }
    }
    

    @IBAction func selectContursButton(_ sender: UIButton) {
        selectContursCount += 1
        if selectContursCount > 3 {
            enableSelectConturs = true
            enablePadSelect = enablePad
            showSelectConturs()
        }
    }
    
    @IBAction func infoButton(_ sender: UIButton) {
        infoMode = !infoMode
        if infoMode {
            infoButtonLabel.setTitleColor(UIColor.red, for: .normal)
            infoButtonLabel.applyRedBorder()
            infoLabel.text = "Установлен справочно-информационный режим. \n Для выхода нажмите кнопку \"Инфо\"."
            infoPresent(0)
        }
        else {
            infoButtonLabel.setTitleColor(UIColor.blue, for: .normal)
            infoButtonLabel.applyBlueBorder()
            infoLabel.text = "Cправочно-информационный режим отключен."
        }
    }
    
    func infoPresent(_ index : Int){
        let alertError = UIAlertController (title: InfoData().titleText[index], message: InfoData().messageText[index], preferredStyle: .actionSheet)
        let action = UIAlertAction (title: "понятно", style: .cancel, handler: nil )
        alertError.addAction(action)
        present(alertError, animated: true, completion: nil)
    }
    
    // Отображаем соответствующее нажатой кнопке всплывающее меню
    @IBAction func selectedButtonTable(_ sender: UIButton) {
        pressedButton = Int(sender.restorationIdentifier!)!
        print("\(pressedButton)")
        func setRedButton(_ offset: Int){
            conturButton[pressedButton-3+offset].layer.borderColor = UIColor.red.cgColor
            conturButton[pressedButton-3+offset].setTitleColor(UIColor.red, for: .normal)
        }
        if enableSelectConturs {
            switch pressedButton {
            case 3,4:
                enablePadSelect[0] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-3)).intValue)
                enablePadSelect[1] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton)).intValue)
            case 5,8...10:
                enablePadSelect[0] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-3)).intValue)
            case 6,7:
                enablePadSelect[0] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-3)).intValue)
                enablePadSelect[1] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-1)).intValue)
            case 11...13:
                enablePadSelect[1] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-11)).intValue)
            case 14,15:
                enablePadSelect[0] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-14)).intValue)
                enablePadSelect[1] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-11)).intValue)
            case 17,18:
                enablePadSelect[0] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-14)).intValue)
                enablePadSelect[1] ^= UInt8(NSDecimalNumber(decimal: pow(2, pressedButton-12)).intValue)
            case 16:
                enablePadSelect[0] ^= 4
            case 19:
                enablePadSelect[0] ^= 128
            case 20:
                enablePadSelect[1] ^= 1
            default:
                break
            }
            showSelectConturs()
        }
        else if infoMode {
            switch pressedButton {
            case 0: infoPresent(1)
            case 1: infoPresent(2)
            case 200: infoPresent(6)
            case 201: infoPresent(7)
            case 21...25,28: infoPresent(10)
            case 3...20: infoPresent(11)
            case 26: infoPresent(12)
            case 27: infoPresent(13)
            default:
                break
            }
            
        }
        else {
        switch pressedButton {
        case 0: tappedButton(selectSitButton)
        case 1: tappedButton(massageProgramButton)
        case 200: tappedButton(readMemoryButton)
        case 201: tappedButton(saveMemoryButton)
        case 3...7:
            setRedButton(0)
            setRedButton(11)
            tappedConturButton(conturButton[pressedButton-3])
        case 8...9,12...13:
            setRedButton(0)
            tappedConturButton(conturButton[pressedButton-3])
        case 10...11:
            setRedButton(0)
            setRedButton(9)
            tappedConturButton(conturButton[pressedButton-3])
        case 14...18:
            setRedButton(0)
            setRedButton(-11)
            tappedConturButton(conturButton[pressedButton-3])
        case 19...20: // боковые спина и сидение справа
            setRedButton(0)
            setRedButton(-9)
            tappedConturButton(conturButton[pressedButton-3])
        case 21: // поясница
            setRedButton(-13)
            setRedButton(-12)
            tappedConturButton(contursButton[pressedButton-21])
        case 22: // боковые
            setRedButton(-17)
            setRedButton(-12)
            setRedButton(-11)
            setRedButton(-6)
            setRedButton(-3)
            setRedButton(-2)
            tappedConturButton(contursButton[pressedButton-21])
        case 23: // все
            for index in -20 ... -3 {
                setRedButton(index)
            }
            tappedConturButton(contursButton[pressedButton-21])
        case 24: // спина верх
            setRedButton(-21)
            setRedButton(-20)
            setRedButton(-10)
            setRedButton(-9)
            tappedConturButton(contursButton[pressedButton-21])
        case 25: // сидение
            setRedButton(-13)
            setRedButton(-12)
            tappedConturButton(contursButton[pressedButton-21])
        case 26:
            heatButton.layer.borderColor = UIColor.red.cgColor
            tappedConturButton(heatButton)
        case 27:
            ventButton.layer.borderColor = UIColor.red.cgColor
            tappedConturButton(ventButton)
        case 28: // спина низ
            setRedButton(-22)
            setRedButton(-21)
            setRedButton(-11)
            setRedButton(-10)
            tappedConturButton(contursButton[pressedButton-23])
        default:
            break
        }
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
        
        if button == readMemoryButton || button == saveMemoryButton {
            popOverVC?.sourceView = readMemoryButton
            popOverVC?.sourceRect = CGRect(x: readMemoryButton.bounds.minX, y: readMemoryButton.bounds.midY, width: 0, height: 0)
            forTableButtonWidth = massageProgramButton.bounds.width
        }
        else {
            popOverVC?.sourceView = button
            popOverVC?.sourceRect = CGRect(x: button.bounds.midX, y: button.bounds.maxY, width: 0, height: 0)
            forTableButtonWidth = button.bounds.width
        }
        self.present(popVC, animated: true)
    }
    
    func tappedConturButton(_ button : UIButton!){
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") else { return }
        popVC.modalPresentationStyle = .popover
        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.sourceView = renewButton
        popOverVC?.sourceRect = CGRect(x:  renewButton.bounds.maxX + 17 , y: renewButton.bounds.maxY + 230, width: 0, height: 0)
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
        
        tempLabel.layer.cornerRadius =   tempLabel.frame.size.height / 7
        tempLabel.layer.borderColor = UIColor.systemGray2.cgColor
        tempLabel.layer.borderWidth = 1
        pressLabel.layer.cornerRadius =   pressLabel.frame.size.height / 7
        pressLabel.layer.borderColor = UIColor.systemGray2.cgColor
        pressLabel.layer.borderWidth = 1

        
        
        playPauseButton.applyBlueBorder()
        stopButton.applyBlueBorder()
        replayButton.applyBlueBorder()
        massageProgramButton.applyBlueBorder()
        selectSitButton.applyBlueBorder()
        readMemoryButton.applyBlueBorder()
        saveMemoryButton.applyBlueBorder()
        returnMemoryButton.applyBlueBorder()
        renewButton.applyBlueBorder()
        infoButtonLabel.applyBlueBorder()
        
 //       playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
 //       stopButton.isEnabled = false
    
 
        for index in 0...5 { contursButton[index].applyBlueBorder() }
        
        heatButton.layer.cornerRadius =  heatButton.frame.size.height / 7
        heatButton.layer.borderColor = UIColor.white.cgColor
        heatButton.layer.borderWidth = CGFloat(1)
        ventButton.layer.cornerRadius =  ventButton.frame.size.height / 7
        ventButton.layer.borderColor = UIColor.white.cgColor
        ventButton.layer.borderWidth = CGFloat(1)
  
        
    }
    

    // func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    // }
    
// Проверяем на включение блютуза, и если включено, начинаем сканировать
// Проверка включен ли Bluetooth. Предупреждение и выход если выключен
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            
            infoLabel.text = "Поиск и установление соединения с сидением \(numberSelectedSit + 1) . . ."
            selectSitButton.layer.backgroundColor = UIColor.darkGray.cgColor
            tempLabel.text = "Темп."
            pressLabel.text = "Давл."
        }
        else {
            let alertBTOff = UIAlertController (title: "ВНИМАНИЕ ! Bluetooth выключен !", message: "Для работы приложения необходимо включить в настройках функцию Bluetooth.", preferredStyle: .alert)
            let action = UIAlertAction (title: "OK", style: .default, handler: nil /*{ _ in exit(0)}*/ )
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
            BTConnect = true
            self.manager.stopScan()
            self.peripheral = peripheral
            self.peripheral.delegate = self
            manager.connect(peripheral, options: nil)
            infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1)."
            selectSitButton.layer.backgroundColor = UIColor.systemGreen.cgColor
      }
      else {

       //     infoBTLabel.text! += "Соединение не установлено \r"
      }
 
    }
    
    func BTConnectInit(){
        infoLabel.text = "Поиск и установление соединения с сидением \(numberSelectedSit + 1) . . ."
        selectSitButton.layer.backgroundColor = UIColor.darkGray.cgColor
        massageProgramButton.layer.backgroundColor = UIColor.darkGray.cgColor
        tempLabel.text = "Темп."
        pressLabel.text = "Давл."
        timeMassageLabel.text = "0:00"


        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        replayButton.setImage(UIImage(systemName: "arrow.turn.down.right"), for: .normal)
        enablePad = [0,0]
        heatLevel = 0 // Уровень обогрева
        ventLevel = 0 // Уровень вентиляции
        reciveData = []
        setPad = [0,0]
        workPad = [0,0]
        pressure = 0 // Текущее давление в блоке
        temperature = 0 // Текущая температура в блоке
        massageRun = false // Работа массажа
        massagePause = false // Выключена пауза работы массажа
        massageRep = false // Выключен повтор работы программы массажа
        pressureWork = false // Не идет процесс установки давлений
        alarmStop = false // Нет аварийной остановки работы блока
        codeError = 0 // Код ошибки
        conturError = 0 // Контур ошибки
        errorFlags = [false, false, false, false, false, false, false,] // Ошибки
        massageSeconds = 0
        massageMinuts = 0
        heatButton.setImage(UIImage(named: "heat\(heatLevel)"), for: .normal)
        ventButton.setImage(UIImage(named: "vent\(ventLevel)"), for: .normal)
        setTextButtonPads("white")
    }
    
    func reconnectBT() {
        if peripheral != nil {
            manager.cancelPeripheralConnection(peripheral)
        }
        manager.scanForPeripherals(withServices: nil, options: nil)
        BTConnectInit()
    }
    
    // Устанавливаем соединение с выбранным переферийным устройством
    func centralManager(
      _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        BTConnect = true
        infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1)."
        selectSitButton.layer.backgroundColor = UIColor.systemGreen.cgColor
    }
    
    // Разрываем соединение и включаем сканирование переферийных устройств
    func centralManager(
      _ central: CBCentralManager,
        didDisconnectPeripheral
            peripheral: CBPeripheral, error: Error?) {
      
        peripheral.discoverServices(nil)
        BTConnect = false
        central.scanForPeripherals(withServices: nil, options: nil)
        BTConnectInit()
    }

    // Опознаем характеристики переферийного устройства
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService, error: Error?){
    // Пролистываем существующие характеристики, определяем нам
    // нужную и включаем контроль обновления данных для этой характеристики,
        
        for characteristic in service.characteristics! {
           let thisCharacteristic = characteristic as CBCharacteristic
           if characteristic.uuid == BT_SCRATCH_UUID {
               charSend = characteristic
               self.peripheral.setNotifyValue(true, for: thisCharacteristic)
           }
        }
    }

    // Отправить данные (массив valueSend) для нужной характеристики (макс. 125 байт)
    func sendData(){
        if BTConnect {
            if !valueSend.isEmpty && charSend != nil {
               let data = NSData(bytes: &valueSend, length: valueSend.count)
               peripheral.writeValue(data as Data, for: charSend!,type: CBCharacteristicWriteType.withoutResponse)
               valueSend = []
  //             print("\(peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withoutResponse))")
            }
        }
    }

    // Поступление данных с переферийного устройства
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        // Проверяем, что это данные с нужного нам UUID
        if characteristic.uuid == BT_SCRATCH_UUID {
            if let charac1 = characteristic.value {
                if let content = String(data: charac1, encoding: String.Encoding.ascii) {
                    reciveData = []
                    for codeUnit in content.utf16{
//                        let st = String(format:"%02X", codeUnit)
                        reciveData.append(UInt8(codeUnit))
                        
 
                    }
 //                   infoLabel.text = "\(reciveData.count) : \(reciveData)"
                    

                    if (reciveData.count == 18) {
                        let temp = Int(90.0 - (Float(reciveData[10]) / 2))
                        let press = (Float(reciveData[11]) - 11) * 0.22

                        if temp > 0 { tempLabel.text = "+\(temp) C" }
                        else { tempLabel.text = "\(temp) C" }
                        pressLabel.text = "\(String(format:"%4.1F", (press))) kPa "
                        
                        if enablePad[0] != reciveData[0] {
                            enablePad[0] = reciveData[0]
                            if pressureWork {setTextButtonPads("gray")}
                            else {setTextButtonPads("white")}
                        }
                        if enablePad[1] != reciveData[1] {
                            enablePad[1] = reciveData[1]
                            if pressureWork {setTextButtonPads("gray")}
                            else {setTextButtonPads("white")}
                        }

                        var pressureContursNew : [UInt8] = []
                        for index in 0...4 {
                            pressureContursNew.append(reciveData[index+2] >> 4)
                            pressureContursNew.append(reciveData[index+2] & 0x0F)
                        }
                        pressureContursNew.append(reciveData[7] >> 4)
                        if pressureConturs != pressureContursNew {
                            pressureConturs = pressureContursNew
                            if pressureWork {setTextButtonPads("gray")}
                            else {setTextButtonPads("white")}
                        }
                        
                        if heatLevel != reciveData[8]{
                            heatLevel = reciveData[8]
                            heatButton.layer.borderColor = UIColor.white.cgColor
                            heatButton.setImage(UIImage(named: "heat\(heatLevel)"), for: .normal)
                        }
                        if ventLevel != reciveData[9]{
                            ventLevel = reciveData[9]
                            ventButton.layer.borderColor = UIColor.white.cgColor
                            ventButton.setImage(UIImage(named: "vent\(ventLevel)"), for: .normal)
                        }
                        
                        temperature = reciveData[10]
                        pressure = reciveData[11]
                        
                        

                        if massageRun != ((reciveData[12] & 1) != 0){
                            massageRun = ((reciveData[12] & 1) != 0)
                            if massageRun && !massagePause {
                                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                                massageProgramButton.layer.backgroundColor = UIColor.systemGreen.cgColor
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Работает программа массажа ..."
                            }
                            else if massageRun && massagePause {
                                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                                massageProgramButton.layer.backgroundColor = UIColor.systemGreen.cgColor
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Включена пауза работы программы массажа ..."
                            }
                            else {
                                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                                massageProgramButton.layer.backgroundColor = UIColor.darkGray.cgColor
                                setTextButtonPads("white")
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Завершена работа программы массажа."                            }
                       
                        }
                        if massagePause != ((reciveData[12] & 2) != 0){
                            massagePause = ((reciveData[12] & 2) != 0)
                            if (massagePause && massageRun) {
                                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Включена пауза работы программы массажа ..."
                            }
                            else if !massageRun {
                                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                            }
                            else {
                                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Работает программа массажа ..."
                            }
                        }
                        if massageRep != ((reciveData[12] & 4) != 0){
                            massageRep = ((reciveData[12] & 4) != 0)
                            if !massageRep {replayButton.setImage(UIImage(systemName: "arrow.turn.down.right"), for: .normal)}
                            else {replayButton.setImage(UIImage(systemName: "arrow.2.squarepath"), for: .normal)}
                        }
                        if pressureWork != ((reciveData[12] & 8) != 0){
                            pressureWork = ((reciveData[12] & 8) != 0)
                            if pressureWork {
                                setTextButtonPads("gray")
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Идёт настройка сидения ..."
                            }
                            else {
                                setTextButtonPads("white")
                                infoLabel.text = "Установлено соединение с сидением \(numberSelectedSit + 1). \n Завершена настройка сидения."
                            }
                        }
                        if errorFlags[0] != ((reciveData[13] & 1) != 0){
                            errorFlags[0] = ((reciveData[13] & 1) != 0)
                            if errorFlags[0] { codeError = 0 }
                        }
                        if errorFlags[1] != ((reciveData[13] & 2) != 0){
                            errorFlags[1] = ((reciveData[13] & 2) != 0)
                            if errorFlags[1] { codeError = 1 }
                        }
                        if errorFlags[2] != ((reciveData[13] & 4) != 0){
                            errorFlags[2] = ((reciveData[13] & 4) != 0)
                            if errorFlags[2] { codeError = 2 }
                        }
                        if errorFlags[3] != ((reciveData[13] & 8) != 0){
                            errorFlags[3] = ((reciveData[13] & 8) != 0)
                            if errorFlags[3] { codeError = 3 }
                        }
                        if errorFlags[4] != ((reciveData[13] & 16) != 0){
                            errorFlags[4] = ((reciveData[13] & 16) != 0)
                            if errorFlags[4] { codeError = 4 }
                        }
                        if errorFlags[5] != ((reciveData[13] & 32) != 0){
                            errorFlags[5] = ((reciveData[13] & 32) != 0)
                            if errorFlags[5] { codeError = 5 }
                        }
                        if errorFlags[6] != ((reciveData[13] & 64) != 0){
                            errorFlags[6] = ((reciveData[13] & 64) != 0)
                            if errorFlags[6] { codeError = 6 }
                        }
                        if massageMinuts != reciveData[14]{
                            massageMinuts = reciveData[14]
                            timeMassageLabel.text = "\(massageMinuts):\(massageSeconds)"
                        }
                        if massageSeconds != reciveData[15]{
                            massageSeconds = reciveData[15]
                            timeMassageLabel.text = "\(massageMinuts):\(String(format:"%02D", massageSeconds))"
                        }
                        if workPad[0] != reciveData[16]{
                            workPad[0] = reciveData[16]
                        }
                        if workPad[1] != reciveData[17]{
                            workPad[1] = reciveData[17]
                        }
                        if alarmStop != ((reciveData[12] & 16) != 0){
                            alarmStop = ((reciveData[12] & 16) != 0)
                            if alarmStop {
                                conturError = 11
                                for index in 0...7 {
                                    if (workPad[0] >> index) & 1 == 1 {
                                        if conturError != 11 {
                                            conturError = 11
                                            break
                                        }
                                        conturError = index
                                    }
                                }
                                if workPad[0] == 0 {
                                    for index in 0...2 {
                                        if (workPad[1] >> index) & 1 == 1 {
                                            if conturError != 11 {
                                                conturError = 11
                                                break
                                            }
                                            conturError = index + 8
                                            break
                                        }
                                    }
                                }
                                switch codeError {
                                case 0,3,4:
                                    let alertError = UIAlertController (title: "ОШИБКА !", message: "\(textError[codeError])", preferredStyle: .alert)
                                    let action = UIAlertAction (title: "OK", style: .default, handler: nil )
                                    alertError.addAction(action)
                                    present(alertError, animated: true, completion: nil)
                                case 1,2,5,6:
                                    let alertError = UIAlertController (title: "ОШИБКА !", message: "\(textError[codeError]) \n ( \(textConturError[conturError]) )", preferredStyle: .alert)
                                    let action = UIAlertAction (title: "OK", style: .default, handler: nil )
                                    alertError.addAction(action)
                                    present(alertError, animated: true, completion: nil)
                                default:
                                    break
                                }
                            }
                        }
                        
                    }
 
                }
            }
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
        // Отключение блокировки экрана
        UIApplication.shared.isIdleTimerDisabled = true
        manager = CBCentralManager(delegate: self, queue: nil)
        modButton()
        
// Восстановление сохраненных данных массива sit или инициализация если их нет
        if let data = defaults.value(forKey: "data") as? Data{
                sit = try!  PropertyListDecoder().decode([Sit].self,from: data)
        }
        else{
            sit = Array(repeating: Sit(), count: 8)
        }
        setTextButtonPads("white")

        heatButton.setImage(UIImage(named: "heat\(heatLevel)"), for: .normal)
        ventButton.setImage(UIImage(named: "vent\(ventLevel)"), for: .normal)
        replayButton.imageEdgeInsets = UIEdgeInsets(top: 23, left: 55, bottom: 26, right: 60)
        playPauseButton.imageEdgeInsets = UIEdgeInsets(top: 23, left: 55, bottom: 26, right: 60)
        
        NotificationCenter.default.addObserver(self, selector: #selector(selectAction), name: NSNotification.Name("ChangeBN"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setTextButtonPadsWhite), name: NSNotification.Name("ChangeWhite"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setTimer), name: NSNotification.Name("Timer"), object: nil)
    }
    
    // Организация функции по таймеру
    let timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            NotificationCenter.default.post(name: NSNotification.Name("Timer"), object: nil)
    }
    
    @objc func setTimer(){
        if selectContursCount > 0 { selectContursCount -= 1} // Для включения настройки количества контуров
        if massageRun && massagePause && timerBlink {
            timeMassageLabel.text = " "
        }
        else { timeMassageLabel.text = "\(massageMinuts):\(String(format:"%02D", massageSeconds))" }
        
        if pressureWork {
            if timerBlink {
                for index in 0...7 {
                    if ((workPad[0] >> index) & 0x01) != 0{
                        conturButton[index].applyAtributeButton("red", Int(pressureConturs[index])+1)
                        if index == 2 { conturButton[index+11].applyAtributeButton("red", Int(pressureConturs[index])+1)}
                        if index == 7 { conturButton[index+9].applyAtributeButton("red", Int(pressureConturs[index])+1)}
                    }
                }
                for index in 8...10 {
                    if ((workPad[1] >> (index-8)) & 0x01) != 0 {
                        conturButton[index].applyAtributeButton("red", Int(pressureConturs[index])+1)
                        if index == 8 { conturButton[index+9].applyAtributeButton("red", Int(pressureConturs[index])+1)}
                    }
                }
                for index in 11...12 {
                    if ((workPad[1] >> (index-8)) & 0x01) != 0 {
                        conturButton[index].applyAtributeButton("red", Int(pressureConturs[index-11])+1)
                    }
                }
                for index in 14...15 {
                    if ((workPad[1] >> (index-9)) & 0x01) != 0 {
                        conturButton[index].applyAtributeButton("red", Int(pressureConturs[index-11])+1)
                    }
                }
            }
            else { setTextButtonPads("gray")}
        }
        else if massageRun {
            if timerBlink {
                for index in 0...7 {
                    if ((workPad[0] >> index) & 0x01) != 0{
                        conturButton[index].applyAtributeButton("yellow", 20)
                        if index == 2 { conturButton[index+11].applyAtributeButton("yellow", 20)}
                        if index == 7 { conturButton[index+9].applyAtributeButton("yellow", 20)}
                    }
                }
                for index in 8...12 {
                    if ((workPad[1] >> (index-8)) & 0x01) != 0 {
                        conturButton[index].applyAtributeButton("yellow", 20)
                        if index == 8 { conturButton[index+9].applyAtributeButton("yellow", 20)}
                    }
                }
                for index in 14...15 {
                    if ((workPad[1] >> (index-9)) & 0x01) != 0 {
                        conturButton[index].applyAtributeButton("yellow", 20)
                    }
                }
            }
            else { setTextButtonPads("gray")}
        }
        
        timerBlink = !timerBlink
    }
    
    // Отображаем текущее давление в кнопках контуров и соответствующую толщину контура белым цветом
    @objc func setTextButtonPadsWhite(){
        if pressureWork || massageRun{ setTextButtonPads("gray") }
        else { setTextButtonPads("white") }
    }
    
    func setTextButtonPads(_ color : String){
        func setCTEButton(_ index : Int, _ offset : Int, _ enabled : Bool) {
            if enabled {
                conturButton[index + offset].applyAtributeButton(color, Int(pressureConturs[index])+1)
                conturButton[index + offset].setTitle("\(pressureConturs[index])", for: .normal)
                conturButton[index + offset].isEnabled = (color == "white") ? true : false
            }
            else {
                conturButton[index + offset].applyWhiteBorder(0)
                conturButton[index + offset].setTitle(" ", for: .normal)
                conturButton[index + offset].isEnabled = false
            }
        }
        
        for index in 0...7 {
            if ((enablePad[0] >> index) & 0x01) != 0{
                setCTEButton(index, 0, true)
                if index == 2 {setCTEButton(index, 11, true)}
                if index == 7 {setCTEButton(index, 9, true)}
            }
            else {
                setCTEButton(index, 0, false)
                if index == 2 {setCTEButton(index, 11, false)}
                if index == 7 {setCTEButton(index, 9, false)}
            }
        }
        for index in 8...10 {
            if ((enablePad[1] >> (index-8)) & 0x01) != 0{
                setCTEButton(index, 0, true)
                if index == 8 {setCTEButton(index, 9, true)}
            }
            else {
                setCTEButton(index, 0, false)
                if index == 8 {setCTEButton(index, 9, false)}
            }
        }
        for index in 11...12 {
            if ((enablePad[1] >> (index-8)) & 0x01) != 0 {setCTEButton(index-11, 11, true)}
            else {setCTEButton(index-11, 11, false)}
        }
        for index in 14...15 {
            if ((enablePad[1] >> (index-9)) & 0x01) != 0 {setCTEButton(index-11, 11, true)}
            else {setCTEButton(index-11, 11, false)}
        }
        
        heatButton.layer.borderColor = UIColor.white.cgColor
        ventButton.layer.borderColor = UIColor.white.cgColor
        
        if massageRun {playPauseButton.isEnabled = true}
        else {playPauseButton.isEnabled = (color == "white") ? true : false}
        
        if color == "white" {
            selectSitButton.setTitleColor(UIColor.white, for: .normal)
            massageProgramButton.setTitleColor(UIColor.white, for: .normal)
            readMemoryButton.setTitleColor(UIColor.white, for: .normal)
            saveMemoryButton.setTitleColor(UIColor.white, for: .normal)
            returnMemoryButton.setTitleColor(UIColor.white, for: .normal)
            renewButton.setTitleColor(UIColor.white, for: .normal)

            selectSitButton.isEnabled = true
            massageProgramButton.isEnabled = true
            readMemoryButton.isEnabled = true
            saveMemoryButton.isEnabled = true
            returnMemoryButton.isEnabled = true
            renewButton.isEnabled = true

            for index in 0...5 { // Кнопки групп контуров
                contursButton[index].setTitleColor(UIColor.white, for: .normal)
                contursButton[index].isEnabled = true
            }
        }
        else {
            selectSitButton.setTitleColor(UIColor.gray, for: .normal)
            massageProgramButton.setTitleColor(UIColor.gray, for: .normal)
            readMemoryButton.setTitleColor(UIColor.gray, for: .normal)
            saveMemoryButton.setTitleColor(UIColor.gray, for: .normal)
            returnMemoryButton.setTitleColor(UIColor.gray, for: .normal)
            renewButton.setTitleColor(UIColor.gray, for: .normal)
            
            selectSitButton.isEnabled = false
            massageProgramButton.isEnabled = false
            readMemoryButton.isEnabled = false
            saveMemoryButton.isEnabled = false
            returnMemoryButton.isEnabled = false
            renewButton.isEnabled = false
            
            for index in 0...5 { // Кнопки групп контуров
                contursButton[index].setTitleColor(UIColor.gray, for: .normal)
                contursButton[index].isEnabled = false
            }
        }
    }
 
    func showSelectConturs() {
        func showSelectContur(_ index : Int, _ offset : Int, _ enabled : Bool){
            conturButton[index + offset].isEnabled = true
            if enabled { conturButton[index + offset].applyAtributeButton("red", 20) }
            else { conturButton[index + offset].applyAtributeButton("white", 20) }
        }
        for index in 0...7 {
            if ((enablePadSelect[0] >> index) & 0x01) != 0{
                showSelectContur(index, 0, true)
                if index == 2 {showSelectContur(index, 11, true)}
                if index == 7 {showSelectContur(index, 9, true)}
            }
            else {
                showSelectContur(index, 0, false)
                if index == 2 {showSelectContur(index, 11, false)}
                if index == 7 {showSelectContur(index, 9, false)}
            }
        }
        for index in 8...10 {
            if ((enablePadSelect[1] >> (index-8)) & 0x01) != 0{
                showSelectContur(index, 0, true)
                if index == 8 {showSelectContur(index, 9, true)}
            }
            else {
                showSelectContur(index, 0, false)
                if index == 8 {showSelectContur(index, 9, false)}
            }
        }
        for index in 11...12 {
            if ((enablePadSelect[1] >> (index-8)) & 0x01) != 0 {showSelectContur(index-11, 11, true)}
            else {showSelectContur(index-11, 11, false)}
        }
        for index in 14...15 {
            if ((enablePadSelect[1] >> (index-9)) & 0x01) != 0 {showSelectContur(index-11, 11, true)}
            else {showSelectContur(index-11, 11, false)}
        }
    }
    
    // Выполняем соответствующее действие выбранной строке всплывающего меню
    @objc func selectAction(){
        switch pressedButton {
        case 0: // Выбор массажного сидения
            selectSitButton.setTitle("Массажное сидение \(selectedTableRow + 1)", for: .normal)
            numberSelectedSit = selectedTableRow
            reconnectBT()
            enablePad = [0,0]
        case 1: // Выбор программы массажа (клапана)
            massageProgramButton.setTitle(massageNames[selectedTableRow], for: .normal)
            selectedMassage = selectedTableRow
        case 200: // Восстановление данных из памяти
            if pressureConturs != sit[numberSelectedSit].pressureMem[selectedTableRow]{
                sit[numberSelectedSit].pressureMem[3] = pressureConturs
                transmitPressure = sit[numberSelectedSit].pressureMem[selectedTableRow]
                setPad = [0,0]
                sendNewPressure() // Отправить новые данные давления по BT
            }
            setTextButtonPads("white")
        case 201: // Сохранение данных в памяти
            sit[numberSelectedSit].pressureMem[selectedTableRow] = pressureConturs
        case 3...13:
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3] = UInt8(selectedTableRow)
            setPad[0] = 1
            setPad[0] = setPad[0] << (pressedButton-3)
            if setPad[0] == 0 {
                setPad[1] = 1
                setPad[1] = setPad[1] << (pressedButton-11)
            }
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 14...18:
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-11] = UInt8(selectedTableRow)
            setPad[0] = 1
            setPad[0] = setPad[0] << (pressedButton-14)
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 19:
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-9] = UInt8(selectedTableRow)
            setPad[0] = 128
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 20:
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-9] = UInt8(selectedTableRow)
            setPad[1] = 1
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 21: // Поясница
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-13] = UInt8(selectedTableRow)
            transmitPressure[pressedButton-3-12] = UInt8(selectedTableRow)
            setPad[0] = 96
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 22: // Боковые
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-17] = UInt8(selectedTableRow)
            transmitPressure[pressedButton-3-12] = UInt8(selectedTableRow)
            transmitPressure[pressedButton-3-11] = UInt8(selectedTableRow)
            setPad[0] = 132
            setPad[1] = 1
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 23: // Все
            for index in 0...10 {
                transmitPressure[index] = UInt8(selectedTableRow)
            }
            setPad[0] = 255
            setPad[1] = 7
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
         case 24: // Спина верх
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-21] = UInt8(selectedTableRow)
            transmitPressure[pressedButton-3-20] = UInt8(selectedTableRow)
            setPad[0] = 03
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 28: // Спина низ
           transmitPressure = pressureConturs
           transmitPressure[pressedButton-3-22] = UInt8(selectedTableRow)
           transmitPressure[pressedButton-3-21] = UInt8(selectedTableRow)
           setPad[0] = 24
           sendNewPressure() // Отправить новые данные давления по BT
           setTextButtonPads("white")
        case 25: // Сидение
            transmitPressure = pressureConturs
            transmitPressure[pressedButton-3-13] = UInt8(selectedTableRow)
            transmitPressure[pressedButton-3-12] = UInt8(selectedTableRow)
            setPad[1] = 6
            sendNewPressure() // Отправить новые данные давления по BT
            setTextButtonPads("white")
        case 26:
            if BTConnect {
                valueSend = [7]
                valueSend.append(UInt8(selectedTableRow))
                sendData()
            }
            heatButton.layer.borderColor = UIColor.white.cgColor
        case 27:
            if BTConnect {
                valueSend = [8]
                valueSend.append(UInt8(selectedTableRow))
                sendData()
            }
            ventButton.layer.borderColor = UIColor.white.cgColor
        default:
            break
        }
    }
 
    func sendNewPressure(){
        if BTConnect {
            valueSend = [2]
            valueSend.append(setPad[0])
            valueSend.append(setPad[1])
            setPad = [0,0]
            valueSend.append(UInt8(selectedTableRow))
            for index in 0...10 {
                valueSend.append(transmitPressure[index])
            }
            sendData()
        }
    }

    
}

