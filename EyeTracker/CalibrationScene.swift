//
//  CalibrationScene.swift
//  EyeTracker
//
//  Created by Victor Schneuwly on 22.04.2024.
//

import SpriteKit
import UIKit

class CalibrationScene: SKScene {
    var calibrationDelegate: CalibrationDelegate?

    private let target = SKShapeNode(circleOfRadius: 75)
    private var instruction: SKShapeNode!
    private var navigator: SKShapeNode!

    private var calibrationPoints: [CGPoint] = []
    private var currentPointIndex = 0

    private var username = ""

    private var calibrationDatas: [CalibrationData] = []
    private var currentState = CalibrationState.base {
        didSet {
            calibrationDelegate?.onCalibrationStateChange(state: currentState)
            updateUI(for: currentState)
        }
    }

    private var countdownActions: SKAction!
    private let countdownDuration = 3
    private var isCountdownRunning = false

    override func sceneDidLoad() {
        // Setup ui
        target.name = "target"
        target.fillColor = .red
        target.strokeColor = .yellow
        target.lineWidth = 50
        target.zPosition = 1
        target.isHidden = true
        addChild(target)

        instruction = createInstruction(size: CGSize(width: size.width * 0.6, height: 200))
        instruction.position = CGPoint(x: size.width / 2, y: size.height / 2 - 200)
        addChild(instruction)

        navigator = createNavigator()
        navigator.position = CGPoint(x: (size.width - 400) / 2, y: size.height - 250)
        addChild(navigator)

        // Add the points to the list
        calibrationPoints = createCalibrationPoints()

        countdownActions = createCountdownActions()
        updateUI(for: currentState)
    }

    func startCalibration() {
        isUserInteractionEnabled = true
        askForUsername()
    }

    func stopCalibration() {
        // exit early if we are in the base state
        if case .base = currentState { return }

        // Remove the target
        target.isHidden = true

        // export the calibration data into the EyeTracker folder
        do {
            // Use a timestamp to make sure the file is unique
            // use the format: yyyy-MM-dd-HH-mm-ss
            let timestamp = Date().ISO8601Format().replacingOccurrences(of: ":", with: "-")
            let filename = "calibrationData_\(timestamp).csv"
            print("Filename: \(filename)")
            let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename).path
            try exportCalibrationData(to: filePath)
            print("Exporting calibration data to: \(filePath)")
        } catch {
            print("Error exporting calibration data: \(error)")
        }

        currentState = .base
    }

    private func askForUsername() {
        let alert = UIAlertController(title: "Enter a username", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Name"
        }

        // Ok button
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [self] _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else {
                askForUsername()
                return
            }
            username = name
            currentState = .calibration(target.position, .middle, .regular)
        })

        // Cancel button
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        guard let viewController = view?.window?.rootViewController else { return }
        viewController.present(alert, animated: true)
    }

    private func createCalibrationPoints() -> [CGPoint] {
        let possibleXs = [0, size.width / 2, size.width]
        let possibleYs = [0, size.height / 2, size.height]
        return possibleYs.flatMap { pty in
            possibleXs.map { ptx in
                CGPoint(x: ptx, y: pty)
            }
        }
    }

    private func createInstruction(size: CGSize) -> SKShapeNode {
        // Define the size and position of the background rectangle
        let background = SKShapeNode(rectOf: size, cornerRadius: 10)
        background.fillColor = .white
        background.strokeColor = .clear

        // Create the instructional text labels
        let positionToScreenText = createLabel(
            called: "positionToScreen", with: "First instruction", at: CGPoint(x: 0, y: 40)
        )
        positionToScreenText.horizontalAlignmentMode = .center

        let headPositionText = createLabel(
            called: "headPosition", with: "Second instruction", at: CGPoint(x: 0, y: 10)
        )
        headPositionText.horizontalAlignmentMode = .center

        let countdownText = createLabel(
            called: "countdown", with: "Countdown", at: CGPoint(x: 0, y: -40), fontSize: 30, bold: true
        )
        countdownText.horizontalAlignmentMode = .center

        // Add labels as children to the background node
        background.addChild(positionToScreenText)
        background.addChild(headPositionText)
        background.addChild(countdownText)

        return background
    }

    private func createCountdownActions() -> SKAction {
        let countdownText = instruction.childNode(withName: "countdown") as? SKLabelNode
        let countdownTextFontSize = countdownText?.fontSize
        return SKAction.sequence([
            // Setup
            SKAction.run {
                self.isCountdownRunning = true
            },

            // Actual countdown
            SKAction.run {
                countdownText?.text = "3"

                // increase the font size
                countdownText?.fontSize = 50
            },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                countdownText?.text = "2"
            },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                countdownText?.text = "1"
            },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                countdownText?.text = "Don't move"
            },

            // End
            SKAction.run {
                // reset the font size
                countdownText?.fontSize = countdownTextFontSize ?? 30
                self.target.fillColor = .orange
            },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                self.target.fillColor = .red
            },
        ])
    }

    // MARK: - User Interface

    private func updateUI(for state: CalibrationState) {
        guard let instruction = instruction,
              let positionToScreenText = instruction.childNode(withName: "positionToScreen") as? SKLabelNode,
              let headPositionText = instruction.childNode(withName: "headPosition") as? SKLabelNode,
              let countdownText = instruction.childNode(withName: "countdown") as? SKLabelNode
        else { return }

        switch state {
        case .base:
            // Write the initial instructions
            positionToScreenText.text = "While looking at the target, hold the device at the specified distance."
            headPositionText.text = "For each point, move your head in the direction indicated."
            countdownText.text = "Press on the screen to start the calibration"

            target.isHidden = true

            // simply hide the navigator
            navigator.isHidden = true

        case let .calibration(position, headPosition, positionToScreen):
            positionToScreenText.text = positionToScreen.instruction()
            headPositionText.text = headPosition.instruction()
            countdownText.text = "Press on the screen to start the countdown"

            // update the point
            target.isHidden = false
            target.position = position

            navigator.isHidden = false
            updateNavigatorLabels(headPosition: headPosition, positionToScreen: positionToScreen)
        default:
            break
        }
    }

    private func updateNavigatorLabels(headPosition: HeadPosition, positionToScreen: PositionToScreen) {
        guard let navigator = navigator,
              let pointNumberLabel = navigator.childNode(withName: "pointNumberLabel") as? SKLabelNode,
              let headPositionLabel = navigator.childNode(withName: "headPositionLabel") as? SKLabelNode,
              let positionToScreenLabel = navigator.childNode(withName: "positionToScreenLabel") as? SKLabelNode,
              let validateButton = navigator.childNode(withName: "validateButton") as? SKLabelNode,
              let cancelButton = navigator.childNode(withName: "cancelButton") as? SKLabelNode
        else { return }

        pointNumberLabel.text = "Point number: \(currentPointIndex + 1)"
        headPositionLabel.text = "Head Position: \(headPosition.rawValue)"
        positionToScreenLabel.text = "Position to Screen: \(positionToScreen.rawValue)"

        // Hide the buttons
        validateButton.isHidden = true
        cancelButton.isHidden = true
    }

    func createNavigator() -> SKShapeNode {
        let background = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 400, height: 225), cornerRadius: 10)
        background.fillColor = .white
        background.strokeColor = .clear
        background.name = "navigator"

        // Setup Point Number Label
        let pointNumberLabel = createLabel(
            called: "pointNumberLabel",
            with: "Point number: \(currentPointIndex + 1)",
            at: CGPoint(x: 10, y: 175),
            bold: true
        )

        // Setup HeadPosition Label
        let headPositionLabel = createLabel(
            called: "headPositionLabel",
            with: "Head Position:",
            at: CGPoint(x: 10, y: 125),
            bold: true
        )

        // Setup PositionToScreen Label
        let positionToScreenLabel = createLabel(
            called: "positionToScreenLabel",
            with: "Position to Screen:",
            at: CGPoint(x: 10, y: 75),
            bold: true
        )

        // Setup validation button
        let validateButton = createLabel(
            called: "validateButton",
            with: "Validate",
            at: CGPoint(x: 250, y: 25),
            bold: true
        )
        validateButton.fontColor = .blue
        validateButton.isHidden = true

        // Setup cancel button
        let cancelButton = createLabel(
            called: "cancelButton",
            with: "Cancel",
            at: CGPoint(x: 80, y: 25),
            bold: true
        )
        cancelButton.fontColor = .red
        cancelButton.isHidden = true

        // Add the labels and buttons to the background node
        background.addChild(pointNumberLabel)
        background.addChild(headPositionLabel)
        background.addChild(positionToScreenLabel)
        background.addChild(validateButton)
        background.addChild(cancelButton)

        return background
    }

    private func createLabel(
        called name: String, with text: String, at position: CGPoint, fontSize: CGFloat = 20, bold: Bool = false
    ) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontSize = fontSize
        label.fontColor = .black
        label.horizontalAlignmentMode = .left
        label.position = position
        label.name = name
        label.fontName = bold ? "Helvetica-Bold" : "Helvetica"

        return label
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard let touch = touches.first else { return }

        switch currentState {
        case .base:
            // Start the calibration
            startCalibration()
        case let .calibration(_, headPosition, positionToScreen):
            // Check if touch is within the navigator
            let location = touch.location(in: self)
            if navigator.contains(location) {
                let localLocation = touch.location(in: navigator)
                handleNavigatorTouch(at: localLocation)
                return
            }

            if isCountdownRunning { return }

            instruction.childNode(withName: "countdown")?.run(countdownActions) { [self] in
                // Store the calibration data
                guard let calibrationDelegate = calibrationDelegate,
                      let calibrationData = calibrationDelegate.getCalibrationData(
                          of: username, for: target.position, position: headPosition, distance: positionToScreen
                      )
                else {
                    if let countdownText = instruction.childNode(withName: "countdown") as? SKLabelNode {
                        countdownText.text = "An error occurred. Please try again."
                    }
                    target.fillColor = .red
                    isCountdownRunning = false
                    return
                }

                calibrationDatas.append(contentsOf: calibrationData)

                // Go to the next point
                currentPointIndex += 1
                currentPointIndex %= calibrationPoints.count

                // If we saw all the points, change the head position
                let nextHeadPosition = currentPointIndex == 0 ? headPosition.next() : headPosition

                // once we did all head positions for all points we need to change our position to the screen
                let nextPositionToScreen =
                    currentPointIndex == 0 && nextHeadPosition == .middle
                        ? positionToScreen.next()
                        : positionToScreen

                // once we circled through everything we are done
                if currentPointIndex == 0 && nextHeadPosition == .middle && nextPositionToScreen == .regular {
                    currentState = .done
                    stopCalibration()
                } else {
                    currentState = .calibration(
                        calibrationPoints[currentPointIndex], nextHeadPosition, nextPositionToScreen
                    )
                }

                self.isCountdownRunning = false
            }
        default:
            return
        }
    }

    private func handleNavigatorTouch(at location: CGPoint) {
        if let node = navigator.atPoint(location) as? SKLabelNode,
           let pointNumberLabel = navigator.childNode(withName: "pointNumberLabel") as? SKLabelNode,
           let headPositionLabel = navigator.childNode(withName: "headPositionLabel") as? SKLabelNode,
           let positionToScreenLabel = navigator.childNode(withName: "positionToScreenLabel") as? SKLabelNode,
           let validateButton = navigator.childNode(withName: "validateButton") as? SKLabelNode,
           let cancelButton = navigator.childNode(withName: "cancelButton") as? SKLabelNode
        {
            // get the selected values from the labels
            let nextPointPosition = Int(
                pointNumberLabel.text!.split(separator: ":")
                    .last!.trimmingCharacters(in: .whitespaces)
            )!
            let headPosition = HeadPosition(
                rawValue: headPositionLabel.text!.split(separator: ":")
                    .last!.trimmingCharacters(in: .whitespaces)
            )!
            let positionToScreen = PositionToScreen(
                rawValue: positionToScreenLabel.text!.split(separator: ":")
                    .last!.trimmingCharacters(in: .whitespaces)
            )!

            // show the buttons
            validateButton.isHidden = false
            cancelButton.isHidden = false

            switch node.name {
            case "validateButton":
                currentPointIndex = nextPointPosition - 1
                currentState = .calibration(
                    calibrationPoints[currentPointIndex], headPosition, positionToScreen
                )

            case "cancelButton":
                // simply reset the labels
                updateUI(for: currentState)

            case "pointNumberLabel":
                pointNumberLabel.text = "Point number: \((nextPointPosition % calibrationPoints.count) + 1)"

            case "headPositionLabel":
                headPositionLabel.text = "Head Position: \(headPosition.next().rawValue)"

            case "positionToScreenLabel":
                positionToScreenLabel.text = "Position to Screen: \(positionToScreen.next().rawValue)"

            default:
                break
            }
        }
    }

    // MARK: - Data export

    func exportCalibrationData(to filePath: String) throws {
        if calibrationDatas.isEmpty {
            throw NSError(
                domain: "CalibrationScene",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No calibration data available"]
            )
        }

        let csvContent = calibrationDatas.reduce(CalibrationData.csvHeader) { acc, data in
            acc + "\n" + data.csvRepresentation()
        }

        try csvContent.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}

// MARK: - Calibration Delegate

protocol CalibrationDelegate: AnyObject {
    func getCalibrationData(
        of name: String, for target: CGPoint, position: HeadPosition, distance: PositionToScreen
    ) -> [CalibrationData]?
    func onCalibrationStateChange(state: CalibrationState)
}
