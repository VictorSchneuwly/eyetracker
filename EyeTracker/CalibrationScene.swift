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

    private let target = SKShapeNode(circleOfRadius: 25)
    private var instruction: SKShapeNode!

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
        target.strokeColor = .clear
        target.zPosition = 1

        instruction = createInstruction(size: CGSize(width: size.width * 0.6, height: 200))
        instruction.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(instruction)

        // Add the points to the list
        calibrationPoints = createCalibrationPoints()

        countdownActions = createCountdownActions()
        updateUI(for: currentState)
    }

    func startCalibration() {
        isUserInteractionEnabled = true
        showUI()
        askForUsername()
    }

    func stopCalibration() {
        isUserInteractionEnabled = false
        removeAllChildren()

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

    private func showUI() {
        // Setup target
        target.position = calibrationPoints[currentPointIndex]
        addChild(target)
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [self] _ in
            // simply close the alert
        })

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
        let positionToScreenText = SKLabelNode(text: "First instruction")
        positionToScreenText.name = "positionToScreen"
        positionToScreenText.fontColor = .black
        positionToScreenText.fontSize = 20
        positionToScreenText.position = CGPoint(x: 0, y: 40)

        let headPositionText = SKLabelNode(text: "Second instruction")
        headPositionText.name = "headPosition"
        headPositionText.fontColor = .black
        headPositionText.fontSize = 20
        headPositionText.position = CGPoint(x: 0, y: 10)

        let countdownText = SKLabelNode(text: "Countdown")
        countdownText.name = "countdown"
        countdownText.fontColor = .black
        countdownText.fontSize = 30 // Larger font size
        countdownText.fontName = "Helvetica-Bold" // Using a bold font
        countdownText.position = CGPoint(x: 0, y: -40)

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
                self.target.fillColor = .yellow
            },
            SKAction.wait(forDuration: 1),
            SKAction.run {
                self.target.fillColor = .red
            },
        ])
    }

    private func updateUI(for state: CalibrationState) {
        guard let instruction = instruction else { return }
        let positionToScreenText = instruction.childNode(withName: "positionToScreen") as? SKLabelNode
        let headPositionText = instruction.childNode(withName: "headPosition") as? SKLabelNode
        let countdownText = instruction.childNode(withName: "countdown") as? SKLabelNode

        switch state {
        case .base:
            // Write the initial instructions
            positionToScreenText?.text = "While looking at the target, hold the device at the specified distance."
            headPositionText?.text = "For each point, move your head in the direction indicated."
            countdownText?.text = "Press on the screen to start the calibration"

        case let .calibration(_, headPosition, positionToScreen):
            positionToScreenText?.text = positionToScreen.instruction()
            headPositionText?.text = headPosition.instruction()
            countdownText?.text = "Press on the screen to start the countdown"
        default:
            break
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        if isCountdownRunning { return }
        guard let touch = touches.first else { return }

        switch currentState {
        case .base:
            // Start the calibration
            startCalibration()
        case let .calibration(_, headPosition, positionToScreen):

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

                let nextHeadPosition = headPosition.next()

                // once we saw all the head positions we need to change the target position
                if nextHeadPosition == .middle {
                    currentPointIndex += 1
                    currentPointIndex %= calibrationPoints.count
                    target.position = calibrationPoints[currentPointIndex]
                }

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
                        target.position, nextHeadPosition, nextPositionToScreen
                    )
                }

                self.isCountdownRunning = false
            }
        default:
            return
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
