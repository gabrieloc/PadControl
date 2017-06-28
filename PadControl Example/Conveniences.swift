//
//  Conveniences.swift
//  PadControl Example
//
//  Created by Gabriel O'Flaherty-Chan on 2017-06-27.
//  Copyright © 2017 gabrieloc. All rights reserved.
//

import UIKit

extension UIView {
  func fillSuperview() {
    guard let constraints = constraintsFillingSuperview() else {
      return
    }
    constraints.forEach { $0.isActive = true }
  }

  func constraintsFillingSuperview() -> [NSLayoutConstraint]? {
    guard let superview = self.superview else {
      print("\(self) must be in view hierarchy")
      return nil
    }
    translatesAutoresizingMaskIntoConstraints = false
    return [topAnchor.constraint(equalTo: superview.topAnchor),
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            superview.rightAnchor.constraint(equalTo: rightAnchor),
            superview.bottomAnchor.constraint(equalTo: bottomAnchor)]
  }
}
