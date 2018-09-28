//
//  PostListTableViewController.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchBarDelegate {
    
    var resultsArray: [SearchableRecord]?
    var isSearching: Bool = false

    
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(postsChanged), name: PostController.PostsChangedNotification, object: nil)
        
        fetchAllPosts()
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resultsArray = PostController.shared.posts
        tableView.reloadData()
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        let filteredPosts = PostController.shared.posts.filter{ $0.matches(searchTerm: searchText) }.compactMap{ $0 as SearchableRecord }
        resultsArray = filteredPosts
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        resultsArray = PostController.shared.posts
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearching = false
    }
    
    @objc func postsChanged(_ notification: Notification) {
        tableView.reloadData()
    }
    
    func fetchAllPosts() {
        PostController.shared.fetchAllPostsFromCloudKit { (posts) in
            
            if posts != nil {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                self.showAlertMessage(title: "Error Fetching Posts", message: "Fix this.")
            }
        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return isSearching ? resultsArray?.count ?? 0 : PostController.shared.posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell
        let dataSource = isSearching ? resultsArray : PostController.shared.posts
        let post = dataSource?[indexPath.row]

        // Configure the cell...
        cell?.post = post as? Post

        return cell ?? UITableViewCell()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "postToDetailVC" {
            let destinationVC = segue.destination as? PostDetailTableViewController
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            let post = PostController.shared.posts[indexPath.row]
            destinationVC?.post = post
        }
    }
}
