//
//  TableViewController.swift
//  AGT-SitControl
//
//  Created by Иван Андриянов on 18.11.2020.
//

import UIKit



class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isScrollEnabled = false
        
    }
    
    // Обработчик если в таблице ничего не выбрано
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: NSNotification.Name("ChangeWhite"), object: nil)
    }
    
    // Определяем размер таблицы
    override func viewWillLayoutSubviews() {
        if pressedButton < 3 {
          preferredContentSize = CGSize(width:  forTableButtonWidth + 15 , height: tableView.contentSize.height - 15)
        }
        else {
            preferredContentSize = CGSize(width:  forTableButtonWidth + 15 , height: tableView.contentSize.height)
        }
    }

    // Определяем количество секций в таблице
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Определяем количество строк в секциях
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch pressedButton {
        case 0:
            return 8
        case 1:
            return massageNames.count
        case 200,201:
            return 3
        case 3...28:
            return 6
        default:
            return 0
        }
    }

    // Определяем содержимое ячеек
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.textColor = UIColor.white
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.darkGray
        cell.selectedBackgroundView = bgColorView


        switch pressedButton {
        case 0:
            cell.textLabel?.text = "Массажное сидение  \(indexPath.row + 1)"
        case 1:
            cell.textLabel?.text = massageNames[indexPath.row]
        case 200:
            cell.textLabel?.text = "Загрузить настройки из памяти \(indexPath.row + 1)"
        case 201:
            cell.textLabel?.text = "Сохранить настройки в память \(indexPath.row + 1)"
        case 3...28:
            cell.textLabel?.text = "\(indexPath.row)"
        default:
            break
        }
        return cell
    }
    
    // Определяем номер выбранной ячейки и запускаем соответствующий обработчик
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTableRow = indexPath.row
        NotificationCenter.default.post(name: NSNotification.Name("ChangeBN"), object: nil)
        dismiss(animated: true, completion: nil)
    }
    
}
