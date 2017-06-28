//
//  ViewController.swift
//  PadControl Example
//
//  Created by Gabriel O'Flaherty-Chan on 2017-06-27.
//  Copyright © 2017 gabrieloc. All rights reserved.
//

import UIKit
import PadControl

class ViewController: UIViewController {

  @IBOutlet weak var omniDirectionalContainer: UIView!
  @IBOutlet weak var xBidirectionalContainer: UIStackView!
  @IBOutlet weak var yBidirectionalContainer: UIStackView!

  override func viewDidLoad() {
    super.viewDidLoad()

    let omniPad = PadControl(directions: .all, planes: 3)
    omniPad.addTarget(self, action: #selector(padUpdated), for: .valueChanged)
    omniDirectionalContainer.backgroundColor = .clear
    omniDirectionalContainer.addSubview(omniPad)
    omniPad.fillSuperview()

    xBidirectionalContainer.arrangedSubviews.forEach { view in
      let idx = xBidirectionalContainer.arrangedSubviews.index(of: view)
      let directions: PadDirections = idx == 0 ? [.left] : idx == 1 ? [.right] : [.left, .right]
      let padControl = PadControl(directions: directions)
      padControl.addTarget(self, action: #selector(padUpdated), for: .valueChanged)
      view.backgroundColor = .clear
      view.addSubview(padControl)
      padControl.fillSuperview()
    }

    yBidirectionalContainer.arrangedSubviews.forEach { view in
      let idx = yBidirectionalContainer.arrangedSubviews.index(of: view)
      let directions: PadDirections = idx == 0 ? [.up] : idx == 1 ? [.down] : [.up, .down]
      let padControl = PadControl(directions: directions)
      padControl.addTarget(self, action: #selector(padUpdated), for: .valueChanged)
      view.backgroundColor = .clear
      view.addSubview(padControl)
      padControl.fillSuperview()
    }
  }

  @objc func padUpdated(sender: PadControl) {

    let u = sender.value(forDirection: .up)
    let r = sender.value(forDirection: .right)
    let d = sender.value(forDirection: .down)
    let l = sender.value(forDirection: .left)

    var description = ""
    description += u > 0 ? "⬆️ \(u)" : ""
    description += r > 0 ? "➡️ \(r)" : ""
    description += d > 0 ? "⬇️ \(d)" : ""
    description += l > 0 ? "⬅️ \(l)" : ""
    print(description)
  }
}
