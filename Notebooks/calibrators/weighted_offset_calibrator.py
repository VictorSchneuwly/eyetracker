from typing import Tuple

import numpy as np

from .calibration_utils import CalibrationData


class WeightedOffsetCalibrator:
    def __init__(self, calibration_data: [CalibrationData]):
        self.average_offset = self.__compute_offset(calibration_data)

    def __compute_offset(
        self, calibration_data: [CalibrationData]
    ) -> Tuple[float, float]:
        weighted_sum = np.zeros(2)
        total_weight = 0.0

        # Weight by how much the face is looking straight
        for data in calibration_data:
            face_forwardness = self.__compute_face_forwardness(data.face_transform)

            offset = np.array(data.gaze_point) - np.array(data.target_point)
            weighted_sum += offset * face_forwardness
            total_weight += face_forwardness

        return weighted_sum / total_weight if total_weight != 0 else np.zeros(2)

    def __compute_face_forwardness(self, face_transform: np.ndarray) -> float:
        # Assuming face_transform is a 4x4 matrix and we're interested in the third column
        z_direction = face_transform[
            :3, 2
        ]  # Extract the third column, first three elements
        unit_vector = np.array([0, 0, 1])
        return max(0.0, np.dot(z_direction, unit_vector))

    def calibrate(self, point: Tuple[float, float]) -> Tuple[float, float]:
        # Applying the average offset to the provided point
        calibrated_point = np.array(point) - self.average_offset
        return tuple(calibrated_point)
