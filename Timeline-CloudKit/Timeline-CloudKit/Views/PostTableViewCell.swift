//
//  PostTableViewCell.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    func updateViews() {
        guard let post = post else { return }
        photoImageView.image = post.photo
        captionLabel.text = post.caption
        commentCountLabel.text = "\(post.comments.count) comments"
        PostController.shared.fetchComments(from: post) { (success) in

            if success {
                DispatchQueue.main.async {
                    self.commentCountLabel.text = "\(post.comments.count) comments"
                }
            }
        }
    }
}
