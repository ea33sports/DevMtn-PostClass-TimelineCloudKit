//
//  AddPostTableViewController.swift
//  Timeline-CloudKit
//
//  Created by Eric Andersen on 9/25/18.
//  Copyright © 2018 Eric Andersen. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PhotoSelectViewControllerDelegate {
    
    var photo: UIImage?

    
    @IBOutlet weak var captionTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toPhotoSelectVC" {
            guard let destinationVC = segue.destination as? PhotoSelectViewController else { return }
            destinationVC.delegate = self
        }
    }
    
    
    func photoSelected(_ photo: UIImage) {
        self.photo = photo
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func addPostButtonTapped(_ sender: Any) {
        
        guard let photo = photo, let caption = captionTextField.text else { return }
        PostController.shared.createPostWith(image: photo, caption: caption) { (post) in
        }
        
        captionTextField.text = ""
        self.tabBarController?.selectedIndex = 0
    }
}
