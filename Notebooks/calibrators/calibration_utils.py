from dataclasses import dataclass
from enum import Enum
from typing import Tuple

import numpy as np


class PositionToScreen(Enum):
    REGULAR = "Regular"
    CLOSE = "Close"
    ARMS_EXTENDED = "Arms Extended"


class HeadPosition(Enum):
    MIDDLE = "Middle"
    TOP = "Top"
    DOWN = "Down"
    LEFT = "Left"
    RIGHT = "Right"


@dataclass
class CalibrationData:
    username: str
    device_name: str
    position: HeadPosition
    distance: PositionToScreen
    timestamp: str
    target_point: Tuple[float, float]
    gaze_point: Tuple[float, float]
    face_transform: np.ndarray  # 4x4 matrix
    right_eye_transform: np.ndarray  # 4x4 matrix
    left_eye_transform: np.ndarray  # 4x4 matrix
    look_at_point: Tuple[float, float, float]


def import_from_csv(filename: str) -> [CalibrationData]:
    # Read the file and return a list of CalibrationData objects
    with open(filename, "r") as file:
        lines = file.readlines()
        # we can remove the first line as it contains the headers
        lines.pop(0)

        return [extract_calibration_data(line) for line in lines]


def extract_calibration_data(line: str) -> CalibrationData:
    # Extract the data from the line and return a CalibrationData object
    # we can split the line by comma
    data = line.split(",")

    return CalibrationData(
        username=data[0],
        device_name=data[1],
        position=HeadPosition(data[2]),
        distance=PositionToScreen(data[3]),
        timestamp=data[4],
        target_point=(float(data[5]), float(data[6])),
        gaze_point=(float(data[7]), float(data[8])),
        face_transform=np.array([float(x) for x in data[9:25]]).reshape((4, 4)),
        right_eye_transform=np.array([float(x) for x in data[25:41]]).reshape((4, 4)),
        left_eye_transform=np.array([float(x) for x in data[41:57]]).reshape((4, 4)),
        look_at_point=(float(data[57]), float(data[58]), float(data[59])),
    )
