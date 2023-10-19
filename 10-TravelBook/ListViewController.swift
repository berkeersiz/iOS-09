//
//  ListViewController.swift
//  10-TravelBook
//
//  Created by Berke Ersiz on 23.08.2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var tableView: UITableView!
    
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var chosenTitle = ""
    var chosenId : UUID?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))
        
        

        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData) , name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func getData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            
            if results.count > 0 {
                
                self.titleArray.removeAll()//Duplica olmasin diye arraylerimizin icini temizliyoruz.
                self.idArray.removeAll()
                
                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id )
                    }
                    tableView.reloadData()
                }
            }
        }catch{
            
        }
    }
    
    @objc func addButtonClicked() {
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC =  segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedId = chosenId
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Core datadan veri silme.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            let idString = idArray[indexPath.row].uuidString//nereye tiklandiysa onun idsi.
            //Fetch request ile veriyi cekip silicem.
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
            let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "id") as? UUID {
                            //iki kere kontrol edip siliyorum cunku geri donusu yok.
                            if id == idArray[indexPath.row] {
                                context.delete(result)
                                titleArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                    
                                } catch {
                                    print("error")
                                }
                                
                                break//aradigim seyi bulup sildiysem for loopun devam etmesine gerek yok.
                                
                            }
                            
                        }
                        
                        
                    }
                    
                    
                }
            } catch {
                print("error")
            }
            
            
            
            
        }
    }
    

}
