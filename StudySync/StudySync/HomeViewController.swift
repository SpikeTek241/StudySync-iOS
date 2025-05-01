//
//  HomeViewController.swift
//  StudySync
//
//  Created by Kevin Jerome on 4/25/25.
//
import UIKit

class HomeViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tasksDueLabel: UILabel!
    @IBOutlet weak var completedTasksLabel: UILabel!
    @IBOutlet weak var upcomingTasksLabel: UILabel!
    @IBOutlet weak var quoteLabel: UILabel!
    @IBOutlet weak var recentTasksTableView: UITableView!

    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        recentTasksTableView.dataSource = self
        recentTasksTableView.layer.cornerRadius = 10
        recentTasksTableView.clipsToBounds = true
        recentTasksTableView.separatorStyle = .none

        loadTasks()
        setupWelcome()
        setupStats()
        fetchQuote()
        styleLabels()
    }

    // MARK: - Style Labels
    func styleLabels() {
        welcomeLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        tasksDueLabel.font = UIFont.systemFont(ofSize: 16)
        completedTasksLabel.font = UIFont.systemFont(ofSize: 16)
        upcomingTasksLabel.font = UIFont.systemFont(ofSize: 16)
        quoteLabel.font = UIFont.italicSystemFont(ofSize: 14)

        let allLabels = [welcomeLabel, dateLabel, tasksDueLabel, completedTasksLabel, upcomingTasksLabel, quoteLabel]
        for label in allLabels {
            label?.textAlignment = .center
            label?.numberOfLines = 0
            label?.adjustsFontSizeToFitWidth = true
        }
    }

    // MARK: - Welcome + Date
    func setupWelcome() {
        welcomeLabel.text = "Good Morning, Pookie!"
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        dateLabel.text = "Today is \(formatter.string(from: Date()))"
    }

    // MARK: - Stats Setup
    func setupStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let dueToday = tasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: today) && !task.isCompleted
            }
            return false
        }

        let completed = tasks.filter { $0.isCompleted }
        let upcoming = tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate > today && !calendar.isDate(dueDate, inSameDayAs: today)
            }
            return false
        }

        tasksDueLabel.text = "📅 Tasks Due Today: \(dueToday.count)"
        completedTasksLabel.text = "✅ Completed Tasks: \(completed.count)"
        upcomingTasksLabel.text = "⏳ Upcoming Tasks: \(upcoming.count)"
    }

    // MARK: - Fetch Random Quote from ZenQuotes API
    func fetchQuote() {
        let url = URL(string: "https://zenquotes.io/api/random")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching quote: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                       let quoteData = jsonArray.first,
                       let quote = quoteData["q"] as? String,
                       let author = quoteData["a"] as? String {

                        DispatchQueue.main.async {
                            self.quoteLabel.text = "\"\(quote)\"\n- \(author)"
                        }
                    }
                } catch {
                    print("Failed to parse quote: \(error)")
                }
            }
        }
        task.resume()
    }

    // MARK: - TableView DataSource for Recent Tasks
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(3, tasks.count)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sortedTasks = tasks.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
        let task = sortedTasks[indexPath.row]

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "RecentTaskCell")
        cell.textLabel?.text = task.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cell.detailTextLabel?.textColor = .gray
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.secondarySystemGroupedBackground
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true

        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            cell.detailTextLabel?.text = "Due: \(formatter.string(from: dueDate))"
        } else {
            cell.detailTextLabel?.text = "No due date"
        }

        return cell
    }

    // MARK: - Load Tasks from UserDefaults
    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: savedData) {
            tasks = decoded
        }
    }

    // MARK: - Button Actions
    @IBAction func addTaskTapped(_ sender: UIButton) {
        tabBarController?.selectedIndex = 1 // Switch to Tasks tab
    }

    @IBAction func goToCalendarTapped(_ sender: UIButton) {
        tabBarController?.selectedIndex = 2 // Switch to Calendar tab
    }
}
