//
//  CaloriesTableViewController.swift
//  CalorieTracker
//
//  Created by Daniela Parra on 10/26/18.
//  Copyright © 2018 Daniela Parra. All rights reserved.
//

import UIKit
import SwiftChart
import CoreData

class CaloriesTableViewController: UITableViewController, ChartDelegate, NSFetchedResultsControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpChart()
        NotificationCenter.default.addObserver(self, selector: #selector(updateChart), name: .didAddCalorie, object: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailyIntakeCell", for: indexPath)
        
        let dailyIntake = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = "Calories: \(dailyIntake.calories)"
        cell.detailTextLabel?.text = dateFormatter.string(for: dailyIntake.date)

        return cell
    }
    
    @IBAction func addIntake(_ sender: Any) {
        let alert = UIAlertController(title: "Add Calorie Intake", message: "Enter the amount of calories in the field", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Calories:"
        }
        
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (alertAction) in
            guard let textField = alert.textFields?.first, let caloriesString = textField.text else { return }
            
            let calories = Int(caloriesString) ?? 0
            self.dailyIntakeController.add(calories: calories)
            
            self.tableView.reloadData()
            
            NotificationCenter.default.post(name: .didAddCalorie, object: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let indexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            //            tableView.moveRow(at: indexPath, to: newIndexPath)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    // MARK: - Swift Chart
    
    func setUpChart() {
        chart = Chart(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: chartView.frame.height))
        chart.delegate = self
        chartView.addSubview(chart)
        
        // Create data set for chart.
        guard let dailyIntakes = fetchedResultsController.fetchedObjects else { return }
        let calories = dailyIntakes.compactMap({ Double($0.calories) })
        let series = ChartSeries(calories)
        series.area = true
        chart.add(series)
    }
    
    @objc func updateChart(_ notification: Notification) {
        chart.series = []
        guard let dailyIntakes = fetchedResultsController.fetchedObjects else { return }
        let calories = dailyIntakes.compactMap({ Double($0.calories) })
        let series = ChartSeries(calories)
        series.area = true
        chart.add(series)
    }
    
    func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
        
    }
    
    func didFinishTouchingChart(_ chart: Chart) {
        
    }
    
    func didEndTouchingChart(_ chart: Chart) {
        
    }
    
    // MARK: - Properties
    
    @IBOutlet weak var chartView: UIView!
    
    private var chart: Chart = Chart(frame: .zero)
    private let dailyIntakeController = DailyIntakeController()
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<DailyIntake> = {
        let fetchRequest: NSFetchRequest<DailyIntake> = DailyIntake.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let moc = CoreDataStack.shared.mainContext
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        frc.delegate = self
        
        try! frc.performFetch()
        return frc
    }()
}

extension Notification.Name {
    static let didAddCalorie = Notification.Name("DidAddCalorie")
}
