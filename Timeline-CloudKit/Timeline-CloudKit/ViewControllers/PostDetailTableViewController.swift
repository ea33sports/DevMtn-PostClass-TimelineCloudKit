//
//  PostDetailTableViewController.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    var post: Post? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }
    
    let dateFormatter: DateFormatter = {
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter
    }()

    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var followButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    func updateViews() {
        guard let post = post else { return }
        imageView.image = post.photo
        
        PostController.shared.checkForSubscription(to: post) { (isSubscribed) in
            
            DispatchQueue.main.async {
                let buttonTitle = isSubscribed ? "Unfollow" : "Follow"
                self.followButton.setTitle(buttonTitle, for: .normal)
            }
        }
    }
    
    func presentCommentAlertController() {
        
        let alertController = UIAlertController(title: "Leave a comment", message: "Tell us your thoughts about this post", preferredStyle: .alert)
        alertController.addTextField { (commentTextField) in
            
            commentTextField.placeholder = "Your comment here"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            guard var commentText = alertController.textFields?.first?.text,
                  let post = self.post else { return }
            PostController.shared.addComment(text: commentText, post: post, completion: { (comment) in
                
                DispatchQueue.main.async {
                    guard let comment = comment else { return }
                    commentText = comment.text
                    self.tableView.reloadData()
                }
            })
        }
        
        let cancenAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancenAction)
        
        present(alertController, animated: true)
    }

    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return post?.comments.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        let comment = post?.comments[indexPath.row]

        // Configure the cell...
        cell.textLabel?.text = comment?.text
        guard let timestamp = comment?.timestamp else { return UITableViewCell() }
        cell.detailTextLabel?.text = dateFormatter.string(for: timestamp)

        return cell
    }
    
    
    @IBAction func commentButtonTapped(_ sender: Any) {
        presentCommentAlertController()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        guard let post = post , let photo = post.photo else { return }
        let activityViewController = UIActivityViewController(activityItems: [photo, post.caption], applicationActivities: nil)
        
        DispatchQueue.main.async {
            self.present(activityViewController, animated: true)
        }
    }
    
    @IBAction func followButtonTapped(_ sender: Any) {
        
        guard let post = post else { return }
        PostController.shared.toggleSubscriptionTo(commentsForPost: post) { (success, error) in
            
            if let error = error {
                print("There was an error following this subscriber: \(error) \(error.localizedDescription)")
                return
            }
            
            if success {
                DispatchQueue.main.async {
                    self.updateViews()
                }
            }
        }
    }
}
