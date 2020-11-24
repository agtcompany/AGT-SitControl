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
    
    // Определяем размер таблицы
    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width:  massageProgramButtonWidth, height: tableView.contentSize.height)
    }

    // Определяем количество секций в таблице
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Определяем количество строк в секциях
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return massageNames.count
    }

    // Определяем содержимое ячеек
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let textData = massageNames[indexPath.row]
        cell.textLabel?.text = textData
        return cell
    }
    
    // Определяем номер выбранной ячейки и меняем текст в кнопке на текст выбранной ячейки
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        massageProgramButtonRow = indexPath.row
        NotificationCenter.default.post(name: NSNotification.Name("ChangeNPM"), object: nil)
        dismiss(animated: true, completion: nil)
    }
    
}
