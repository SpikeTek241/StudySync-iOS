//
//  TasksViewController.swift
//  StudySync
//
//  Created by Kevin Jerome on 4/25/25.
//
import UIKit

struct Task: Codable, Equatable {
    var title: String
    var isCompleted: Bool
    var dueDate: Date?

    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.title == rhs.title && lhs.dueDate == rhs.dueDate
    }
}

class TasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.title = "Tasks"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tableView.backgroundColor = .systemBackground

        loadTasks()
        sortTasks()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTask))
    }

    // MARK: - TableView Data Source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        cell.textLabel?.numberOfLines = 2
        if let dueDate = task.dueDate {
            cell.textLabel?.text = "\(task.title)\nDue: \(dateFormatter.string(from: dueDate))"
        } else {
            cell.textLabel?.text = task.title
        }

        cell.textLabel?.textColor = task.isCompleted ? .systemGray : .label
        cell.accessoryType = task.isCompleted ? .checkmark : .none

        return cell
    }

    // MARK: - Toggle Complete

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tasks[indexPath.row].isCompleted.toggle()
        saveTasks()
        sortTasks()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Swipe to Delete

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("Deleting task at index: \(indexPath.row) - \(tasks[indexPath.row].title)")
            tasks.remove(at: indexPath.row)
            saveTasks()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    // MARK: - Add Task

    @objc func addTask() {
        let alert = UIAlertController(title: "New Task", message: "Enter task title", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Task Title"
        }

        let nextAction = UIAlertAction(title: "Next", style: .default) { _ in
            if let taskTitle = alert.textFields?.first?.text, !taskTitle.isEmpty {
                self.showDatePicker(for: taskTitle)
            }
        }

        alert.addAction(nextAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showDatePicker(for title: String) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels

        let alert = UIAlertController(title: "Pick Due Date", message: "\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)

        datePicker.frame = CGRect(x: 10, y: 20, width: alert.view.bounds.width - 40, height: 150)

        let addAction = UIAlertAction(title: "Add Task", style: .default) { _ in
            let newTask = Task(title: title, isCompleted: false, dueDate: datePicker.date)
            print("Trying to add task: \(newTask.title)")

            if !self.tasks.contains(newTask) {
                self.tasks.append(newTask)
                print("Task added: \(newTask.title)")
            } else {
                print("Duplicate task not added.")
            }

            self.saveTasks()
            self.sortTasks()
            self.tableView.reloadData()
        }

        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        self.present(alert, animated: true)
    }

    // MARK: - Save, Load & Sort Tasks

    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }

    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: savedData) {
            tasks = decoded
        }
    }

    func sortTasks() {
        tasks.sort {
            if $0.isCompleted == $1.isCompleted {
                return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
            }
            return !$0.isCompleted && $1.isCompleted
        }
    }
}
