import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colormaps
import os


def load_df(dir_path):
    """
    Load all CSV files in the specified directory into a single pandas DataFrame using a list comprehension.

    Args:
    dir_path (str): The path to the directory containing CSV files.

    Returns:
    pd.DataFrame: A DataFrame containing all the data from the CSV files.
    """

    def load_from_csv(file_path):
        df = pd.read_csv(os.path.join(dir_path, file_path))
        # Clean up the column names that seem to have leading spaces
        df.columns = df.columns.str.strip()

        if not all(col in df.columns for col in ["roll", "pitch", "yaw"]):
            df[["roll", "pitch", "yaw"]] = df.apply(
                lambda row: extract_euler_angles_from_matrix(
                    extract_face_transform(row)
                ),
                axis=1,
                result_type="expand",
            )

        return df

    # Load each CSV file into a DataFrame
    dfs = [load_from_csv(f) for f in os.listdir(dir_path) if f.endswith(".csv")]

    # Concatenate all DataFrames in the list into one DataFrame, if any are found
    return pd.concat(dfs, ignore_index=True) if dfs else pd.DataFrame()


def extract_face_transform(row) -> np.ndarray:
    return np.array(
        row[[f"faceTransform_{i}_{j}" for i in range(4) for j in ["x", "y", "z", "w"]]]
    ).reshape((4, 4))


def extract_euler_angles_from_matrix(matrix):
    r11, r12, r13, _ = matrix[0]
    r21, r22, r23, _ = matrix[1]
    r31, r32, r33, _ = matrix[2]

    pitch = np.arctan2(-r31, np.sqrt(r32**2 + r33**2))

    if np.isclose(pitch, np.pi / 2):
        yaw = 0
        roll = np.arctan2(r12, r22)
    elif np.isclose(pitch, -np.pi / 2):
        yaw = 0
        roll = -np.arctan2(r12, r22)
    else:
        yaw = np.arctan2(r21, r11)
        roll = np.arctan2(r32, r33)

    return np.degrees(roll), np.degrees(pitch), np.degrees(yaw)


def show_subplots(
    df,
    colormap="tab10",
    with_limits=False,
    xlim=[-100, 1233],
    ylim=[-100, 844],
    with_calib=False,
):
    # Create a figure and a set of subplots in a 3x3 grid
    fig, axs = plt.subplots(3, 3, figsize=(20, 15))
    axs = axs.flatten()

    # Track legend handles and labels
    handles, labels = [], []

    unique_targets = (
        df[["targetPointX", "targetPointY"]].drop_duplicates().reset_index(drop=True)
    )

    colors = colormaps[colormap]

    # Define colors for each position
    positions = df["position"].unique()
    color_dict = {pos: colors(i) for i, pos in enumerate(positions)}

    # Define marker shapes for each distance
    distances = df["distance"].unique()
    markers = ["o", "s", "^"]  # Circle, Square, Triangle
    marker_dict = {dist: markers[i] for i, dist in enumerate(distances)}

    # Plot each target point on a separate subplot
    for idx, (ax, (x, y)) in enumerate(zip(axs, unique_targets.to_numpy())):
        current_data = df[(df["targetPointX"] == x) & (df["targetPointY"] == y)]

        # Plot each combination of position and distance
        for (pos, dist), group_data in current_data.groupby(["position", "distance"]):
            handle = ax.scatter(
                group_data["gazePointX"],
                group_data["gazePointY"],
                color=color_dict[pos],
                marker=marker_dict[dist],
                label=f"Pos: {pos}, Dist: {dist}",
                s=50,
            )
            if idx == 0:  # Only add to legend once
                handles.append(handle)
                labels.append(f"Pos: {pos}, Dist: {dist}")

            if with_calib:
                # also add calibrated point
                ax.scatter(
                    group_data["calibratedPointX"],
                    group_data["calibratedPointY"],
                    color="white",
                    edgecolor=color_dict[pos],
                    marker=marker_dict[dist],
                    label=f"Pos: {pos}, Dist: {dist}",
                    s=50,
                )

        # Plot target point
        ax.scatter(x, y, color="black", label="Target Point", s=100, marker="x")
        ax.set_title(f"Target Point at ({x}, {y})")
        ax.set_xlabel("X Coordinate")
        ax.set_ylabel("Y Coordinate")
        if with_limits:
            ax.set_xlim(xlim)
            ax.set_ylim(ylim)

        ax.grid(True)

    # Hide unused axes if there are fewer than 9 targets
    for i in range(len(unique_targets), 9):
        axs[i].axis("off")

    # Add one legend to the figure
    fig.legend(handles, labels, loc="upper right", bbox_to_anchor=(1.15, 1))

    # Adjust layout to prevent overlap
    plt.tight_layout()

    # Show plot
    plt.show()
