//
//  ViewController.swift
//  PadControl Example
//
//  MIT License
//
//  Copyright (c) 2017 Gabriel O'Flaherty-Chan
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

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
