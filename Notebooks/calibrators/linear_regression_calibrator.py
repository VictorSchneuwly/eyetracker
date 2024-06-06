import numpy as np
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score
from dataclasses import dataclass
from typing import List, Tuple
from .calibration_utils import CalibrationData


class LinearRegressionCalibrator:
    def __init__(self, calibration_data: [CalibrationData]):
        self.model = LinearRegression()
        self.__setup_model(calibration_data)

    def __setup_model(self, calibration_data: List[CalibrationData]):
        X, y = self.__prepare_data(calibration_data)
        self.model.fit(X, y)

    def __prepare_data(self, calibration_data: List[CalibrationData]):
        X = []  # Features
        y = []  # Targets

        for data in calibration_data:
            features = list(data.gaze_point) + list(data.face_transform.flatten())
            X.append(features)
            y.append(data.target_point)

        return np.array(X), np.array(y)

    def calibrate(
        self, point: Tuple[float, float], face_transform: np.ndarray
    ) -> Tuple[float, float]:
        features = list(point) + list(face_transform.flatten())

        # Predict the target point using the model
        predicted_point = self.model.predict([features])
        return tuple(predicted_point[0])

    def evaluate(self, test_data: List[CalibrationData]):
        X_test, y_test = self.__prepare_data(test_data)
        y_pred = self.model.predict(X_test)
        print("X_test:\n", X_test)
        print("true:\n", y_test)
        print("pred:\n", y_pred)
        mse = mean_squared_error(y_test, y_pred)
        rmse = np.sqrt(mse)
        r2 = r2_score(y_test, y_pred)
        return {"MSE": mse, "RMSE": rmse, "R²": r2}
