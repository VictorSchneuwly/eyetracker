from dataclasses import dataclass
from enum import Enum
from typing import Tuple

import pandas as pd
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
    euler_angles: Tuple[float, float, float]
    look_at_point: Tuple[float, float, float]


def import_from_csv(filename: str) -> [CalibrationData]:
    # Read the file and return a list of CalibrationData objects
    with open(filename, "r") as file:
        lines = file.readlines()
        # we can remove the first line as it contains the headers
        lines.pop(0)

        return [extract_calibration_data_from_line(line) for line in lines]


def extract_calibration_data_from_line(line: str) -> CalibrationData:
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
        euler_angles=(float(data[57]), float(data[58]), float(data[59])),
        look_at_point=(float(data[60]), float(data[61]), float(data[62])),
    )


def import_from_dataframe(df) -> [CalibrationData]:
    # Extract the data from the DataFrame and return a list of CalibrationData objects
    return df.apply(extract_calibration_data_from_row, axis=1).tolist()


def extract_calibration_data_from_row(row) -> CalibrationData:
    return CalibrationData(
        username=row["username"],
        device_name=row["deviceName"],
        position=HeadPosition(row["position"]),
        distance=PositionToScreen(row["distance"]),
        timestamp=row["timestamp"],
        target_point=(float(row["targetPointX"]), float(row["targetPointY"])),
        gaze_point=(float(row["gazePointX"]), float(row["gazePointY"])),
        face_transform=np.array(
            row[
                [
                    f"faceTransform_{i}_{j}"
                    for i in range(4)
                    for j in ["x", "y", "z", "w"]
                ]
            ].tolist()
        ).reshape((4, 4)),
        right_eye_transform=np.array(
            row[
                [
                    f"rightEyeTransform_{i}_{j}"
                    for i in range(4)
                    for j in ["x", "y", "z", "w"]
                ]
            ].tolist()
        ).reshape((4, 4)),
        left_eye_transform=np.array(
            row[
                [
                    f"leftEyeTransform_{i}_{j}"
                    for i in range(4)
                    for j in ["x", "y", "z", "w"]
                ]
            ].tolist()
        ).reshape((4, 4)),
        euler_angles=(float(row["roll"]), float(row["pitch"]), float(row["yaw"])),
        look_at_point=(
            float(row["lookAtPointX"]),
            float(row["lookAtPointY"]),
            float(row["lookAtPointZ"]),
        ),
    )


def calib_data_to_dataframe(data):
    # turn a list of CalibrationData objects into a DataFrame
    return pd.DataFrame(
        [
            {
                "username": d.username,
                "deviceName": d.device_name,
                "position": d.position.value,
                "distance": d.distance.value,
                "timestamp": d.timestamp,
                "targetPointX": d.target_point[0],
                "targetPointY": d.target_point[1],
                "gazePointX": d.gaze_point[0],
                "gazePointY": d.gaze_point[1],
                **{
                    f"faceTransform_{i}_{j}": d.face_transform[i, ji]
                    for i in range(4)
                    for (ji, j) in enumerate(["x", "y", "z", "w"])
                },
                **{
                    f"rightEyeTransform_{i}_{j}": d.right_eye_transform[i, ji]
                    for i in range(4)
                    for (ji, j) in enumerate(["x", "y", "z", "w"])
                },
                **{
                    f"leftEyeTransform_{i}_{j}": d.left_eye_transform[i, ji]
                    for i in range(4)
                    for (ji, j) in enumerate(["x", "y", "z", "w"])
                },
                "roll": d.euler_angles[0],
                "pitch": d.euler_angles[1],
                "yaw": d.euler_angles[2],
                "lookAtPointX": d.look_at_point[0],
                "lookAtPointY": d.look_at_point[1],
                "lookAtPointZ": d.look_at_point[2],
            }
            for d in data
        ]
    )
