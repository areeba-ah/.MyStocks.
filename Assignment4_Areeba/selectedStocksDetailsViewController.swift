//
//  selectedStocksDetailsViewController.swift
//  Assignment4_Areeba
//
//  Created by Areeba Abid Mahmood on 2024-11-27.
//

import UIKit

class selectedStocksDetailsViewController: UIViewController {
    
    var stock: Stock?
    
    @IBOutlet weak var stockDetails: UILabel!
    
    @IBOutlet weak var rankOutlet: UISlider!
    
    @IBOutlet weak var myRank: UILabel!
    
    
    var rank: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if stock != nil {
            stockDetails.text = "Name: \(stock?.name ?? "")\nID:\(stock?.id ?? "")\nPerformance ID:\(stock?.performanceId ?? "")\nExchange:\(stock?.exchange ?? "")\nSecurity Type:\(stock?.securityType ?? "")"
        }
        
        rank = Int(stock?.rank ?? 0)
        rankOutlet.value = Float(rank)
        
        updateRankLabel(rank: rank)
        
        print("Rank: \(String(describing: stock?.rank))")

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func setRank(_ sender: UISlider) {
        rank = Int(sender.value)
        
       updateRankLabel(rank: rank)
    }
    
    
    func updateRankLabel(rank: Int){
        if rank == 0 {
            myRank.text = "My Rank: Cold"
        }
        
        else if rank == 1{
            myRank.text = "My Rank: Hot"
        }
        
        else{
            myRank.text = "My Rank: Very Hot"
        }
    }
    
    
    
    @IBAction func saveDetails(_ sender: UIButton) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            // Update the stock's rank
            stock?.rank = Int16(rank)
            
            // Save the context
            do {
                try context.save()
                print("Rank updated successfully to \(rank).")
            } catch {
                print("Failed to update rank: \(error)")
            }
        dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func canelBtn(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)

    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
