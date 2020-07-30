// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import Firebase

class UserViewController: UIViewController, DataSourceProviderDelegate {
  var dataSourceProvider: DataSourceProvider<User>!

  var userImage = UIImageView(systemImageName: "person.circle.fill", tintColor: .secondaryLabel)
  var tableView: UITableView { view as! UITableView }

  private var _user: User?
  var user: User? {
    get { _user ?? Auth.auth().currentUser }
    set { _user = newValue }
  }

  /// Init allows for injecting a `User` instance during UI Testing
  /// - Parameter user: A Firebase User instance
  init(_ user: User? = nil) {
    super.init(nibName: nil, bundle: nil)
    self.user = user
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UIViewController Life Cycle

  override func loadView() {
    view = UITableView(frame: .zero, style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureNavigationBar()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureDataSourceProvider()
    updateUserImage()
  }

  // MARK: - DataSourceProviderDelegate

  func tableViewDidScroll(_ tableView: UITableView) {
    adjustUserImageAlpha(tableView.contentOffset.y)
  }

  func didSelectRowAt(_ indexPath: IndexPath, on tableView: UITableView) {
    let item = dataSourceProvider.item(at: indexPath)

    let actionName = item.isEditable ? item.detailTitle! : item.title!

    guard let action = UserAction(rawValue: actionName) else {
      // The row tapped has no affiliated action.
      return
    }

    switch action {
    case .signOut:
      signCurrentUserOut()

    case .link:
      linkUserToOtherAuthProviders()

    case .requestVerifyEmail:
      requestVerifyEmail()

    case .tokenRefresh:
      refreshCurrentUserIDToken()

    case .delete:
      deleteCurrentUser()

    case .updateEmail:
      presentEditUserInfoController(for: item, to: updateUserEmail)

    case .updateDisplayName:
      presentEditUserInfoController(for: item, to: updateUserDisplayName)

    case .updatePhotoURL:
      presentEditUserInfoController(for: item, to: updatePhotoURL)

    case .refreshUserInfo:
      refreshUserInfo()
    }
  }

  // MARK: - Firebase 🔥

  public func signCurrentUserOut() {
    try? Auth.auth().signOut()
    updateUI()
  }

  public func linkUserToOtherAuthProviders() {
    guard let user = user else { return }
    let accountLinkingController = AccountLinkingViewController(for: user)
    let navController = UINavigationController(rootViewController: accountLinkingController)
    navigationController?.present(navController, animated: true, completion: nil)
  }

  public func requestVerifyEmail() {
    user?.sendEmailVerification { error in
      guard error == nil else { return self.displayError(error) }
      print("Verification email sent!")
    }
  }

  public func refreshCurrentUserIDToken() {
    let forceRefresh = true
    user?.getIDTokenForcingRefresh(forceRefresh) { token, error in
      guard error == nil else { return self.displayError(error) }
      if let token = token {
        print("New token: \(token)")
      }
    }
  }

  public func refreshUserInfo() {
    user?.reload { error in
      if let error = error {
        print(error)
      }
      self.updateUI()
    }
  }

  public func updateUserDisplayName(to newDisplayName: String) {
    let changeRequest = user?.createProfileChangeRequest()
    changeRequest?.displayName = newDisplayName
    changeRequest?.commitChanges { error in
      guard error == nil else { return self.displayError(error) }
      self.updateUI()
    }
  }

  public func updateUserEmail(to newEmail: String) {
    user?.updateEmail(to: newEmail, completion: { error in
      guard error == nil else { return self.displayError(error) }
      self.updateUI()
        })
  }

  public func updatePhotoURL(to newPhotoURL: String) {
    guard let newPhotoURL = URL(string: newPhotoURL) else {
      print("Could not create new photo URL!")
      return
    }
    let changeRequest = user?.createProfileChangeRequest()
    changeRequest?.photoURL = newPhotoURL
    changeRequest?.commitChanges { error in
      guard error == nil else { return self.displayError(error) }
      self.updateUI()
    }
  }

  public func deleteCurrentUser() {
    user?.delete { error in
      guard error == nil else { return self.displayError(error) }
      self.updateUI()
    }
  }

  // MARK: - Private Helpers

  private func configureNavigationBar() {
    navigationItem.title = "User"
    guard let navigationBar = navigationController?.navigationBar else { return }
    navigationBar.prefersLargeTitles = true
    navigationBar.titleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemOrange]
    navigationBar.addProfilePic(userImage)
  }

  private func updateUserImage() {
    guard let photoURL = user?.photoURL else {
      let defaultImage = UIImage(systemName: "person.circle.fill")
      userImage.image = defaultImage?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
      return
    }
    userImage.setImage(from: photoURL)
  }

  private func configureDataSourceProvider() {
    dataSourceProvider = DataSourceProvider(
      dataSource: user?.sections,
      emptyStateView: SignedOutView(),
      tableView: tableView
    )
    dataSourceProvider.delegate = self
  }

  private func updateUI() {
    configureDataSourceProvider()
    animateUpdates(for: tableView)
    updateUserImage()
  }

  private func animateUpdates(for tableView: UITableView) {
    UIView.transition(with: tableView, duration: 0.2,
                      options: .transitionCrossDissolve,
                      animations: { tableView.reloadData() })
  }

  private func presentEditUserInfoController(for item: Itemable,
                                             to saveHandler: @escaping (String) -> Void) {
    let editController = UIAlertController(
      title: "Update \(item.detailTitle!)",
      message: nil,
      preferredStyle: .alert
    )
    editController.addTextField { $0.placeholder = "New \(item.detailTitle!)" }

    let saveHandler: (UIAlertAction) -> Void = { _ in
      let text = editController.textFields!.first!.text!
      saveHandler(text)
    }

    editController.addAction(UIAlertAction(title: "Save", style: .default, handler: saveHandler))
    editController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(editController, animated: true, completion: nil)
  }

  private var originalOffset: CGFloat?

  private func adjustUserImageAlpha(_ offset: CGFloat) {
    originalOffset = originalOffset ?? offset
    let verticalOffset = offset - originalOffset!
    userImage.alpha = 1 - (verticalOffset * 0.05)
  }
}
