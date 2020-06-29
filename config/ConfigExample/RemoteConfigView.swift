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


class RemoteConfigView: UIView {
    
    var topLabel: UILabel!
    var jsonView: UIView!
    var bottomLabel: UILabel!
    
    lazy var fetchButton: UIButton = {
        let button = UIButton()
        button.setTitle("Fetch & Activate Config", for: .normal)
        button.setTitleColor(UIColor.white.highlighted, for: .highlighted)
        button.setBackgroundImage(UIColor.systemOrange.image, for: .normal)
        button.setBackgroundImage(UIColor.systemOrange.highlighted.image, for: .highlighted)
        button.clipsToBounds = true
        button.layer.cornerRadius = 14
        return button
    }()
    
    convenience init() {
        self.init(frame: .zero)
        backgroundColor = .systemBackground
        setupSubviews()
    }
    
    // MARK: - Label Text
    
    private var topInfoLabelText: NSAttributedString {
        let labelText = "Use config to change a label's text %@"
        let symbolName = "wand.and.stars"
        let attributedText = NSMutableAttributedString(text: labelText, textColor: .secondaryLabel, symbol: symbolName, symbolColor: .systemYellow)
        attributedText.setColorForText(text: "text", color: .systemYellow)
        return attributedText
    }
    
    private var jsonInfoLabelText: NSAttributedString {
        let labelText = "%@ Use JSON to configure complex entities"
        let symbolName = "arrow.down.doc.fill"
        let attributedText = NSMutableAttributedString(text: labelText, textColor: .secondaryLabel,
                                              symbol: symbolName, symbolColor: .systemOrange)
        attributedText.setColorForText(text: "JSON", color: .systemOrange)
        return attributedText
    }
    
    private var bottomLabelInfoText: NSAttributedString {
        let labelText = "%@ Define platform or locale-specific content"
        let symbolName = "clock.fill"
        let attributedText = NSMutableAttributedString(text: labelText, textColor: .secondaryLabel, symbol: symbolName, symbolColor: .systemOrange)
        return attributedText
    }
    
    // MARK: - Subview Setup
    
    private func setupSubviews() {
        setupTopSubviews()
        setupJSONSubview()
        setupBottomSubviews()
        setupFetchButton()
    }

    private func setupTopSubviews() {
        let label = UILabel()
        label.attributedText = topInfoLabelText
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        
        topLabel = UILabel()
        topLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(topLabel)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 15),
            label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            topLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            topLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            topLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15)
        ])
    }
    
    private func setupJSONSubview() {
        jsonView = UIView()
        jsonView.backgroundColor = .secondarySystemBackground
        jsonView.layer.cornerRadius = 16
        jsonView.clipsToBounds = true
        jsonView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(jsonView)
        
        let label = UILabel()
        label.attributedText = jsonInfoLabelText
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: jsonView.topAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            jsonView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            jsonView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
            jsonView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor, constant: -30),
            jsonView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.37),
        ])
    }
    
    private func setupBottomSubviews() {
        let label = UILabel()
        label.attributedText = bottomLabelInfoText
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
        
        bottomLabel = UILabel()
        bottomLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(bottomLabel)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: jsonView.bottomAnchor, constant: 30),
            label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            bottomLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            bottomLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            bottomLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15)
        ])
    }
    
    private func setupFetchButton() {
        fetchButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(fetchButton)
        NSLayoutConstraint.activate([
            fetchButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
            fetchButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
            fetchButton.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: -50),
            fetchButton.topAnchor.constraint(greaterThanOrEqualTo: bottomLabel.bottomAnchor, constant: 20),
            fetchButton.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
}

