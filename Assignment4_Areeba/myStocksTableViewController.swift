//
//  myStocksTableViewController.swift
//  Assignment4_Areeba
//
//  Created by Areeba Abid Mahmood on 2024-11-27.
//

import UIKit
import CoreData
import UserNotifications

class myStocksTableViewController: UITableViewController {
    
    var stocks: [Stock] = [] // Array to hold fetched stocks
    var activeStocks: [Stock] = []
    var watchedStocks: [Stock] = []
    var rankStock: String = ""
    var result: String = ""
    
    
    @IBOutlet weak var edit_cancel_btn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the refresh control
        let refreshControl = UIRefreshControl()
               refreshControl.addTarget(self, action: #selector(refreshStockData), for: .valueChanged)
               tableView.refreshControl = refreshControl
        
        fetchStocks()
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "CustomTableViewCell")
        
        self.tableView.reloadData()
    }
    
    // MARK: - Pull-to-Refresh Action
        @objc func refreshStockData() {
           fetchStocks()  // Fetch data again to simulate refresh
    
            // End the refreshing animation
            tableView.refreshControl?.endRefreshing()
        }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch the latest stocks data when the view is about to appear
        fetchStocks()
        
        // Reload the table view with the new data
        tableView.reloadData()
    }
    
    @IBAction func editStocks(_ sender: UIBarButtonItem) {
        
        tableView.setEditing(!tableView.isEditing, animated: true)

        if tableView.isEditing {
            edit_cancel_btn.title = "Done"
        }
        else {
            edit_cancel_btn.title = "Edit"
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedStock: Stock
        
        if indexPath.section == 0 {
            // Active stocks
            selectedStock = activeStocks[indexPath.row]
        } else {
            // Watched stocks
            selectedStock = watchedStocks[indexPath.row]
        }
        
        performSegue(withIdentifier: "showStockDetail", sender: selectedStock)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if section == 0 {
            return activeStocks.count
        }
        else {
            return watchedStocks.count
        }
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as? CustomTableViewCell else {
            return UITableViewCell()
        }
        
        let stock: Stock
        if indexPath.section == 0 {
            stock = activeStocks[indexPath.row]
        } else {
            stock = watchedStocks[indexPath.row]
        }

        // Reset cell state to prevent stale data
        cell.titleLabel.text = stock.name
        cell.subtitleLabel.text = nil

        // Determine rank description
        let rank = stock.rank
        let rankStock: String
        switch rank {
        case 1: rankStock = "Hot"
        case 2: rankStock = "Very Hot"
        default: rankStock = "Cold"
        }

        if let lastUpdate = stock.lastUpdate {
            // If already fetched, directly use it
            cell.subtitleLabel.text = "Rank: \(rankStock)\n\(lastUpdate)"
        } else if let performanceId = stock.performanceId {
            // Fetch lastUpdate asynchronously
            getLastUpdate(performanceId: performanceId) { [weak self, weak stock] result in
                DispatchQueue.main.async {
                    guard let self = self, let stock = stock else { return }

                                 // Update stock's last update
                    if let result = result {
                        stock.lastUpdate = result // Update the actual stock object

                        // Check if cell is still visible
                        if let updatedCell = self.tableView.cellForRow(at: indexPath) as? CustomTableViewCell {
                            updatedCell.subtitleLabel.text = "Rank: \(rankStock)\n\(result)"
                        }
                        
                        // Schedule a local notification when stock update is fetched
                         self.scheduleStockUpdateNotification(stock: stock, updateMessage: result)
                    } else {
                        print("Failed to fetch or decode the data for stock: \(String(describing: stock.name))")
                    }
                    
                }
            }
        } else {
            print("Missing performanceId for stock: \(String(describing: stock.name))")
        }

        return cell
    }



    
    // This method fetches the stock data
    func fetchStocks() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
           let context = appDelegate.persistentContainer.viewContext

           let fetchRequest: NSFetchRequest<Stock> = Stock.fetchRequest()

           do {
               // Perform the fetch request to get the stocks
               self.stocks = try context.fetch(fetchRequest)
               DispatchQueue.main.async {
                   self.tableView.reloadData()  // Reload data on the main thread
               }
               
               // Divide stocks into active and watched
               self.activeStocks = stocks.filter { $0.status == 0 } // Active stocks (status = 0)
               self.watchedStocks = stocks.filter { $0.status == 1 } // Watched stocks (status = 1)

           } catch {
               print("Failed to fetch stocks: \(error)")
           }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Active Stocks"
        } else {
            return "Watch Stocks"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showStockDetail", let stockDetailVC = segue.destination as? selectedStocksDetailsViewController {
            if let selectedStock = sender as? Stock {
                stockDetailVC.stock = selectedStock
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
           return true // Allow movement of rows
       }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
            if sourceIndexPath.section == proposedDestinationIndexPath.section {
                return sourceIndexPath // Prevent movement within the same section
            } else {
                return proposedDestinationIndexPath // Allow movement to the other section
            }
        }


    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        if sourceIndexPath.section != destinationIndexPath.section {
            if sourceIndexPath.section == 0 {
                // Moving from Active to Watched
                let movedStock = activeStocks.remove(at: sourceIndexPath.row)
                watchedStocks.insert(movedStock, at: destinationIndexPath.row)
                movedStock.status = 1 // Update `status` to represent "Watched"
            } else {
                // Moving from Watched to Active
                let movedStock = watchedStocks.remove(at: sourceIndexPath.row)
                activeStocks.insert(movedStock, at: destinationIndexPath.row)
                movedStock.status = 0 // Update `status` to represent "Active"
            }

            do {
                try context.save() // Save changes to Core Data
            } catch {
                print("Failed to save changes: \(error)")
            }

            tableView.reloadData() // Refresh UI
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true  // Allow editing (deleting) rows
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Delete from the data source (activeStocks or watchedStocks)
            var stockToDelete: Stock
            if indexPath.section == 0 {
                stockToDelete = activeStocks[indexPath.row]
                activeStocks.remove(at: indexPath.row)  // Remove from activeStocks
            } else {
                stockToDelete = watchedStocks[indexPath.row]
                watchedStocks.remove(at: indexPath.row)  // Remove from watchedStocks
            }

            //Delete the stock from Core Data
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            context.delete(stockToDelete)

            //Save the context to persist the deletion
            do {
                try context.save()
                print("Stock deleted successfully.")
            } catch {
                print("Failed to delete stock: \(error)")
            }

            // Step 6: Update the table view to reflect the deletion
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Notification scheduling method
    func scheduleStockUpdateNotification(stock: Stock, updateMessage: String) {
        let content = UNMutableNotificationContent()
        content.title = "Stock Update: \(stock.name ?? "Unknown")"
        content.body = updateMessage
        content.sound = .default
        
        // Create trigger to fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "StockUpdate_\(stock.objectID)", content: content, trigger: trigger)
        
        // Add notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Notification scheduled for stock: \(stock.name ?? "Unknown")")
            }
        }
    }


    
    func getLastUpdate(performanceId: String, completion: @escaping (String?) -> Void) {
        let urlString = "https://ms-finance.p.rapidapi.com/stock/v2/get-realtime-data?performanceId=\(performanceId)"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }

        // Set up the request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("72c3bf0585msh554dad757b4e8b6p1528d2jsn24a095060f7f", forHTTPHeaderField: "x-rapidapi-key")
        request.setValue("ms-finance.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 15 // Optional: Set a timeout interval

        // Start the data task
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("HTTP Error: \(httpResponse.statusCode)")
                    completion(nil)
                    return
                }
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let stockData = try decoder.decode(StockData.self, from: data)

                // Safely unwrap optional fields
                let currencySymbol = stockData.currencySymbol ?? "Symbol unavailable"
                let lastPriceString: String
                if let lastPrice = stockData.lastPrice {
                    lastPriceString = "\(currencySymbol) \(lastPrice) (\(stockData.currencyCode ?? "Code unavailable"))"
                    let price = lastPrice
                } else {
                    lastPriceString = "Price unavailable (\(stockData.currencyCode ?? "Code unavailable"))"
                }

                let lastUpdateTimeString = stockData.lastUpdateTime ?? "Update time unavailable"

                // Format the result
                let result = """
                Last Price: \(lastPriceString)
                Last Update: \(lastUpdateTimeString)
                """
                
                let price = stockData.lastPrice
                
                completion(result)
            } catch {
                print("Error decoding JSON: \(error)")
                completion(nil)
            }



        }

        task.resume()
    }

}



