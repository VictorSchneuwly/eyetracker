from typing import Tuple

import numpy as np

from .calibration_utils import CalibrationData


class AverageOffsetCalibrator:
    def __init__(self, calibration_data: [CalibrationData]):
        self.average_offset = self.__compute_offset(calibration_data)

    def __compute_offset(
        self, calibration_data: [CalibrationData]
    ) -> Tuple[float, float]:
        # Extract gaze and target points into separate NumPy arrays
        gaze_points = np.array([data.gaze_point for data in calibration_data])
        target_points = np.array([data.target_point for data in calibration_data])

        # Compute offsets by vectorized subtraction
        offsets = gaze_points - target_points

        # Compute the mean of offsets along the row axis
        return np.mean(offsets, axis=0)

    def calibrate(self, point: Tuple[float, float]) -> Tuple[float, float]:
        # Applying the average offset to the provided point, converting point to NumPy array for operation
        calibrated_point = np.array(point) - self.average_offset
        return tuple(calibrated_point)
