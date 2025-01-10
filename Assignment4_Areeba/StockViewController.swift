//
//  StockViewController.swift
//  Assignment4_Areeba
//
//  Created by Areeba Abid Mahmood on 2024-11-27.
//

import UIKit
import CoreData


class StockViewController: UIViewController {
    
    @IBOutlet weak var stockSelected: UILabel!
    
    @IBOutlet weak var selectedStockStatus: UISegmentedControl!
    
    
    @IBOutlet weak var selectedStockStackView: UIStackView!
    
    
    var selectedIndex: Int = 0
    var stockName: String = ""
    var stockId: String = ""
    var exchange: String = ""
    var performanceId: String = ""
    var stockDescription: String = ""
    var securityType: String = ""
    
    
    lazy var searchResultTableVC = storyboard?.instantiateViewController(withIdentifier: "searchResultTVC") as! SearchResultTableViewController
    lazy var searchController = UISearchController(searchResultsController: searchResultTableVC)
     
    var stock: Stock?
    override func viewDidLoad() {
        
        super.viewDidLoad()
       
 
        selectedStockStackView.isHidden = true
        
        print("StockViewController viewDidLoad")
        if let stock = stock {
                print("Stock is not nil: \(stock)")
                // Edit mode
            } else {
                print("Stock is nil, setting up search controller")
                navigationItem.searchController = searchController
                searchController.searchResultsUpdater = self
                searchResultTableVC.delegate = self
            }
    }
    
    @IBAction func backBtn(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func stockStatus(_ sender: UISegmentedControl) {
            self.selectedIndex = sender.selectedSegmentIndex
            print("Selected index: \(self.selectedIndex)")
    }
    
    
    
   
    @IBAction func saveStock(_ sender: UIButton) {
      
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        // Create new Stock object
        self.stock = Stock(context: context)
        
        // Set values for the stock entity
        self.stock?.setValue(stockName, forKey: "name")
        self.stock?.setValue(performanceId, forKey: "performanceId")
        self.stock?.setValue(selectedIndex, forKey: "status")
        self.stock?.setValue(stockId, forKey: "id")
        self.stock?.setValue(exchange, forKey: "exchange")
        self.stock?.setValue(securityType, forKey: "securityType")
        
        // Debug print to check stock
        print(stock!)

        // Save to Core Data
        do {
            try context.save()
            print("Stock saved successfully.")
            self.dismiss(animated: true, completion: nil)

        } catch {
            print("Failed to save stock: \(error)")
        }
    }
    
    
    @IBAction func cancelSearchScreen(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}


extension StockViewController: UISearchResultsUpdating {
    

        
        func updateSearchResults(for searchController: UISearchController) {
            // Safely unwrap the search text
            guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
                return
            }
            
            // URL encode the search query to avoid issues with special characters
            guard let encodedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                print("Failed to encode search query.")
                return
            }
            
            // Request URL
            let urlString = "https://ms-finance.p.rapidapi.com/market/v2/auto-complete?q=\(encodedSearchText)"
            
            // Network request to fetch data
            Service.shared.getData(from: urlString) { [unowned self] data in
                // Print the raw API response for debugging purposes
                if let rawData = String(data: data, encoding: .utf8) {
                    print("API Response: \(rawData)") // Raw response
                }

                // Attempt to decode the response into ResultValues
                do {
                    let value = try JSONDecoder().decode(ResultValues.self, from: data)
                    
                    // Update the table view with the search results
                    DispatchQueue.main.async {
                        self.searchResultTableVC.stockFromSearch = value.results
                        self.searchResultTableVC.tableView.reloadData() // Reloads with new data
                    }
                } catch {
                    print("Failed to decode the search results: \(error.localizedDescription)")
                    // Optionally handle error by updating the UI (e.g., showing an empty state or an error message)
                }
            }
        }
}


extension StockViewController: SearchResultTableViewControllerDelegate {

    func searchResuleTableViewControllerDidFinishWith(stock: TStock) {
        searchController.isActive = false
        selectedStockStackView.isHidden = false
        
        self.stockName = stock.name
        self.stockId = stock.id
        self.exchange = stock.exchange
        self.performanceId = stock.performanceId
        self.securityType = stock.securityType

        
        stockSelected.text = "Stock Name: \(stock.name) \nPerformance ID: \(stock.performanceId) \nStock ID: \(stock.id) \nExchange: \(stock.exchange) \nSecurity Type: \(stock.securityType)"
        
    }
    
    func setStockStatus(stock: Stock, status: StockStatus) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        // Update the existing stock or create a new entity
        stock.setValue(status.rawValue, forKey: "status") // Update the status

        do {
            try context.save()
            print("Stock details saved successfully with status \(status).")
        } catch {
            print("Failed to save stock details: \(error)")
        }
        
        print("Stock: ",stock)
    }
}




