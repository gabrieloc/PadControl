//
//  PadControl.swift
//  PadControl
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

func lerp(_ lhs: CGFloat, _ rhs: CGFloat, _ percentage: CGFloat, _ exponent: CGFloat = 1.0) -> CGFloat {
  return (rhs - lhs) * pow(percentage, exponent) + lhs
}

func clamp(_ x: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
  return Swift.min(max, Swift.max(min, x))
}

func clamp(_ x: Double, min: Double, max: Double) -> Double {
  return Double(clamp(CGFloat(x), min: CGFloat(min), max: CGFloat(max)))
}

public struct PadDirections: OptionSet {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let up = PadDirections(rawValue: 1 << 0)
  public static let left = PadDirections(rawValue: 1 << 1)
  public static let down = PadDirections(rawValue: 1 << 2)
  public static let right = PadDirections(rawValue: 1 << 3)

  public static let all: PadDirections = [.up, .right, .down, .left]

  public enum Axis {
    case x, y
  }

  var axis: Axis? {
    if contains(.left) || contains(.right) {
      return .x
    } else if contains(.up) || contains(.down) {
      return .y
    }
    return nil
  }

  public func bidirectional(on axis: Axis) -> Bool {
    switch axis {
    case .x:
      return contains(.left) && contains(.right)
    case .y:
      return contains(.up) && contains(.down)
    }
  }

  public func unidirectional(on axis: Axis) -> Bool {
    return !bidirectional(on: axis) && !nondirectional(on: axis)
  }

  public func nondirectional(on axis: Axis) -> Bool {
    switch axis {
    case .x:
      return !contains(.left) && !contains(.right)
    case .y:
      return !contains(.up) && !contains(.down)
    }
  }
}

public class PadControl: UIControl {

  typealias Elevation = Double

  var touchPoint: CGPoint?

  let directions: PadDirections
  let preferredEdgeLength = 88.0
  let dotRadius = 8.0
  let selectionGrowthMultiplier = 1.15
  let selectionGrowthExponent = 2.0
  static let planeCornerRadii = 8.0
  let planeCount: Int

  var strokeColor: UIColor {
    if #available(iOS 13.0, *) {
      return UIColor.systemBackground
    }
    return .white
  }

  var actionColor: UIColor {
    return tintColor
  }

  let containerLayer = CAShapeLayer()
  var planes: [CAShapeLayer]? {
    return containerLayer.sublayers as? [CAShapeLayer]
  }

  public init(directions: PadDirections, planes: Int = 4) {
    self.directions = directions
    self.planeCount = planes

    super.init(frame: .zero)

    preparePlanes(planeCount)
    tintColorDidChange()
  }

  override public func tintColorDidChange() {
    isSelected = false
  }

  override public func layoutSubviews() {
    movePlanes(to: peakOrigin)
  }

  override public var isSelected: Bool {
    didSet {

      planes?.forEach { planeLayer in

        let elevation = planeElevation(for: planeLayer)
        let opacity = isSelected ? CGFloat(planeOpacity(for: elevation)) : CGFloat(1.0)

        let isBaseLayer = planeElevation(for: planeLayer) == 0
        let unselectedAlpha: CGFloat = isBaseLayer ? 0.1 : 0.0
        let fillColor = actionColor.withAlphaComponent(isSelected ? opacity : unselectedAlpha)

        planeLayer.lineWidth = 2.0
        planeLayer.strokeColor = strokeColor.cgColor
        planeLayer.fillColor = fillColor.cgColor

        if let sublayers = planeLayer.sublayers,
          let dotLayer = sublayers.first as? CAShapeLayer {
          dotLayer.fillColor = isSelected ? strokeColor.cgColor : actionColor.cgColor
        }
      }
    }
  }

  @objc (planeElevationForIndex:)
  func planeElevation(for index: Int) -> Elevation {
    return Double(index) / max(1, Double(planeCount) - 1)
  }

  @objc (planeElevationForPlane:)
  func planeElevation(for plane: CAShapeLayer) -> Elevation {

    guard let index = planes?.firstIndex(of: plane) else {
      return 0.0
    }
    return planeElevation(for: index)
  }

  func planeOpacity(for elevation: Elevation) -> Float {
    let opacity = Float(max(0.1, elevation))
    return opacity
  }

  public func value(forAxis axis: PadDirections.Axis) -> Double {
    switch axis {
    case .y:
      return abs(value(forDirection: .up) - value(forDirection: .down))
    case .x:
      return abs(value(forDirection: .right) - value(forDirection: .left))
    }
  }

  public func value(forDirection direction: PadDirections) -> Double {

    guard
      let touchPoint = touchPoint,
      directions.contains(direction),
      let axis = direction.axis
      else {
        return 0.0
    }

    let size = bounds.size
    var value = 0.0

    switch axis {
    case .x:
      let width = Double(size.width)
      let bi = directions.bidirectional(on: .x)
      let widthMultiplier = bi ? 0.5 : 1.0
      let xSubtract: Double = bi ? 1 : 0
      let totalValue = Double(touchPoint.x) / (width * widthMultiplier)
      value = direction.contains(.right) ? totalValue - xSubtract: 1 - totalValue
    case .y:
      let height = Double(size.height)
      let bi = directions.bidirectional(on: .y)
      let heightMultiplier = bi ? 0.5 : 1.0
      let ySubtract: Double = bi ? 1 : 0
      let totalValue = Double(touchPoint.y) / (height * heightMultiplier)
      value = direction.contains(.down) ? totalValue - ySubtract: 1 - totalValue
    }
    return clamp(value, min: 0, max: 1)
  }

  func preparePlanes(_ count: Int) {

    backgroundColor = strokeColor

    for i in 0..<count {
      let elevation = planeElevation(for: i)
      let planeLayer = createPlaneLayer(for: elevation)
      let layerIndex = UInt32(i)
      containerLayer.insertSublayer(planeLayer, at: layerIndex)
    }
    layer.addSublayer(containerLayer)
  }

  func createPlaneLayer(for elevation: Elevation) -> CAShapeLayer {

    let path = planePath(for: elevation)
    let planeLayer = CAShapeLayer()
    planeLayer.path = path.cgPath

    if elevation == 1.0 {
      let dotLayer = CAShapeLayer()
      planeLayer.addSublayer(dotLayer)
    }

    return planeLayer
  }

  func movePlanes(to point: CGPoint, animated: Bool = false) {

    sendActions(for: .valueChanged)

    guard let planes = self.planes else {
      return
    }
    planes.forEach { plane in
      let elevation = planeElevation(for: plane)
      let newPath = self.planePath(for: elevation).cgPath

      if animated {
        animatePath(for: plane, to: newPath)
      } else {
        plane.path = newPath
      }

      if let sublayers = plane.sublayers, let dotLayer = sublayers.first as? CAShapeLayer {
        let r = CGFloat(dotRadius)
        let dotRect = CGRect(origin: CGPoint(x: peakOrigin.x + peakSize.width * 0.5 - r,
          y: peakOrigin.y + peakSize.height * 0.5 - r),
          size: CGSize(width: dotRadius * 2.0,
            height: dotRadius * 2.0))
        let dotPath = UIBezierPath(ovalIn: dotRect).cgPath

        if animated {
          animatePath(for: dotLayer, to: dotPath)
        } else {
          dotLayer.path = dotPath
        }
      }
    }
  }

  func animatePath(for shapeLayer: CAShapeLayer, to path: CGPath, withDuration duration: TimeInterval = 0.05) {

    let animation = CABasicAnimation(keyPath: "path")
    animation.toValue = path
    animation.duration = duration
    animation.fillMode = CAMediaTimingFillMode.forwards
    shapeLayer.add(animation, forKey: nil)
    shapeLayer.path = path
  }

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    guard let touchPoint = touches.first?.location(in: self) else {
      return
    }

    isSelected = true
    let point = clampTouchPoint(touchPoint)
    self.touchPoint = point
    movePlanes(to: point, animated: false)
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    if let touchPoint = touches.first?.location(in: self) {
      let point = clampTouchPoint(touchPoint)
      self.touchPoint = point
      movePlanes(to: point)
    }
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    isSelected = false
    touchPoint = nil
    movePlanes(to: restingPoint, animated: true)
  }

  func planeRect(for elevation: Elevation) -> CGRect {

    let baseRect = bounds
    let baseOrigin = baseRect.origin
    let baseSize = baseRect.size

    let elevation = CGFloat(elevation)
    let exponent = CGFloat(isSelected ? selectionGrowthExponent : 1.0)

    let origin = CGPoint(x: lerp(baseOrigin.x, peakOrigin.x, elevation, exponent),
      y: lerp(baseOrigin.y, peakOrigin.y, elevation, exponent))
    let size = CGSize(width: lerp(baseSize.width, peakSize.width, elevation, exponent),
      height: lerp(baseSize.height, peakSize.height, elevation, exponent))
    return CGRect(origin: origin, size: size)
  }

  func planePath(for elevation: Elevation) -> UIBezierPath {
    let rect = planeRect(for: elevation)
    return UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(PadControl.planeCornerRadii))
  }

  var peakOrigin: CGPoint {

    let size = bounds.size
    let center = touchPoint ?? restingPoint

    let d = directions

    let xOffset = d.bidirectional(on: .x) ? 0.5 : d.contains(.right) ? 1.0 : 0.0
    let yOffset = d.bidirectional(on: .y) ? 0.5 : d.contains(.down) ? 1.0 : 0.0

    let x = center.x - peakSize.width * CGFloat(xOffset)
    let y = center.y - peakSize.height * CGFloat(yOffset)

    let boundedX = max(0.0, min(x, size.width - peakSize.width))
    let boundedY = max(0.0, min(y, size.height - peakSize.height))

    return CGPoint(x: boundedX, y: boundedY)
  }

  var peakSize: CGSize {

    let size = bounds.size
    let fullWidth = Double(size.width)
    let fullHeight = Double(size.height)
    let d = directions

    let xValue = value(forAxis: .x)
    let minWidth = min(preferredEdgeLength, fullWidth * 0.25)
    let xEdgeLength = isSelected ? minWidth * selectionGrowthMultiplier : minWidth
    let dynamicWidth = max(xEdgeLength, fullWidth * xValue)

    let yValue = value(forAxis: .y)
    let minHeight = min(preferredEdgeLength, fullHeight * 0.25)
    let yEdgeLength = isSelected ? minHeight * selectionGrowthMultiplier : minHeight
    let dynamicHeight = max(yEdgeLength, fullHeight * yValue)

    let width = d.nondirectional(on: .x) ? fullWidth : (d.unidirectional(on: .x) ? dynamicWidth : minWidth)
    let height = d.nondirectional(on: .y) ? fullHeight : (d.unidirectional(on: .y) ? dynamicHeight : minHeight)

    return CGSize(width: width, height: height)
  }

  var restingPoint: CGPoint {

    let rect = bounds

    let fullWidth = Double(rect.size.width)
    let fullHeight = Double(rect.size.height)

    let d = directions

    let percentX = d.contains(.left) ? (d.contains(.right) ? 0.5 : 1.0) : 0.0
    let percentY = d.contains(.up) ? (d.contains(.down) ? 0.5 : 1.0) : 0.0

    let x = (fullWidth * percentX)
    let y = (fullHeight * percentY)

    return CGPoint(x: x, y: y)
  }

  func clampTouchPoint(_ touchPoint: CGPoint) -> CGPoint {

    let d = directions

    let size = bounds.size

    let (minX, maxX) = (CGFloat(0.0), size.width)
    let (minY, maxY) = (CGFloat(0.0), size.height)

    let x = d.nondirectional(on: .x) ? size.width * 0.5 : clamp(touchPoint.x, min: minX, max: maxX)
    let y = d.nondirectional(on: .y) ? size.height * 0.5 : clamp(touchPoint.y, min: minY, max: maxY)

    return CGPoint(x: x, y: y)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(directions:) must be used")
  }
}

