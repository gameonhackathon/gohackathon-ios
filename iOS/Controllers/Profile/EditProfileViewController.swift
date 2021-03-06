//
//  EditProfileViewController.swift
//  Game On
//
//  Created by Eduardo Irias on 2/9/17.
//  Copyright © 2017 Game On. All rights reserved.
//

import UIKit

enum PersonalSetting : String {
    case name = "name"
    case username = "username"
    case email = "email"
}

class EditProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ProfileEditPhotoTableViewCellDelegate, EditTableViewCellDelegate {

    var isFromSignUp = false
    var didEditedImage = false
    var personalSettings : [PersonalSetting] = [.name, .username, .email]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.addHideKeyboardWithTapGesture()
        self.addKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeNavigationAndStatusBarToWhite()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        changeNavigationAndStatusBarToClear()
    }
    
    func dismiss() {
        if isFromSignUp {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Actions
    
    @IBAction func saveAction(_ sender: Any) {
        
        guard let user = User.current(),
            let imageCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileEditPhotoTableViewCell,
            let nameCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? EditTableViewCell,
            let usernameCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? EditTableViewCell,
            let emailCell = tableView.cellForRow(at: IndexPath(row: 2, section: 1)) as? EditTableViewCell,
            let aboutCell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? EditTableViewCell else {
                return
        }
        
        if nameCell.input == "" || usernameCell.input == "" || emailCell.input == ""  {
            showSimpleAlert(title: "Oups, your info!", message: "Please fill out the personal info.")
            return
        }
        
        user.name = nameCell.input
        user.username = usernameCell.input
        user.email = emailCell.input
        
        user.bio = aboutCell.input
        
        user.saveEventually()
        
        if didEditedImage {
            let data = UIImageJPEGRepresentation(imageCell.photoImageView.image!, 7.0)
            user.setFile(forKey: #keyPath(User.image), withData: data!, andName: "image.jpeg") { (succeeded, error) in
                self.dismiss()
            }
            return
        }
        
        dismiss()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? personalSettings.count : 1
    }
    
    func getCellIdentifier(forIndexPath indexPath : IndexPath) -> String {
        switch indexPath.section {
        case 0:
            return "ChoosePhotoCell"
        case 1:
            return indexPath.row == 0 ? "EditTitleCell" : "EditCell"
        case 2:
            return "EditAboutCell"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = getCellIdentifier(forIndexPath: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
        
        guard let user = User.current() else {
            return cell
        }
        
        if let cell = cell as? ProfileEditPhotoTableViewCell {
            cell.delegate = self
            user.getFile(forKey: #keyPath(User.image), withBlock: { (data) in
                if let data = data {
                    cell.photoImageView.image = UIImage(data: data)
                }
            })
            
        }
        
        if let cell = cell as? EditTableViewCell {
            cell.delegate = self
            
            if indexPath.section == 1 {
                guard let titleLabel = cell.titleLabel, let inputTextField = cell.inputTextField else {
                    return cell
                }
                titleLabel.text = personalSettings[indexPath.row].rawValue.localizedCapitalized
                inputTextField.placeholder = personalSettings[indexPath.row].rawValue.localizedCapitalized
                
                inputTextField.text = user.object(forKey: personalSettings[indexPath.row].rawValue) as! String?
                
                switch personalSettings[indexPath.row] {
                case .name:
                    inputTextField.autocapitalizationType = .words
                    inputTextField.keyboardType = .default
                case .username, .email:
                    inputTextField.autocapitalizationType = .none
                    inputTextField.keyboardType = .emailAddress
                }
            } else {
                guard let inputTextView = cell.inputTextView else {
                    return cell
                }
                inputTextView.text = user.bio
            }
        }
        
        cell.selectionStyle = .none
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 180
        case 1:
            return indexPath.row == 0 ? 120.0 : 55.0
        case 2:
            return 200
        default:
            return 55
        }
        
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage, let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileEditPhotoTableViewCell  {
            
            cell.photoImageView.image = image.resize(toWidth: 400.00)
            didEditedImage = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - ProfileEditPhotoTableViewCellDelegate
    
    func shouldChoosePhoto() {
        let imageController = UIImagePickerController()
        imageController.sourceType = .photoLibrary
        imageController.delegate = self
        imageController.navigationBar.backgroundColor = UIColor.white
        imageController.allowsEditing = true
        self.present(imageController, animated: true, completion: nil)
    }
    
    // MARK: - EditTableViewCellDelegate
    
    func didEditedTextField(cell: EditTableViewCell, withInput input: String) {
        cell.inputTextField!.resignFirstResponder()
    }
        
}
