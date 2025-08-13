#!/bin/bash
set -e

echo "Starting Docker-specific ASCENT installation..."

# Initialize conda
echo "Initializing conda..."
if ! conda init bash; then
    echo "ERROR: Failed to initialize conda"
    exit 1
fi

# Source conda
echo "Sourcing conda..."
CONDA_BASE=$(conda info --base)/etc/profile.d/conda.sh
if [ ! -f "$CONDA_BASE" ]; then
    echo "ERROR: conda.sh not found at $CONDA_BASE"
    exit 1
fi
if ! source $CONDA_BASE; then
    echo "ERROR: Failed to source conda.sh"
    exit 1
fi
echo "Conda sourced successfully"

# Check if ascent environment already exists
echo "Checking for existing ASCENT environment..."
if conda env list | grep -q "ascent"; then
    echo "ASCENT environment already exists, removing it..."
    if ! conda env remove -n ascent -y; then
        echo "WARNING: Failed to remove existing ascent environment, continuing..."
    else
        echo "Existing ASCENT environment removed successfully"
    fi
else
    echo "No existing ascent environment found"
fi

# Create ascent environment
echo "Creating ASCENT conda environment..."
if ! conda create -n ascent python=3.11 -y; then
    echo "ERROR: Failed to create conda environment"
    if ! conda info --envs; then
        echo "WARNING: Failed to get conda environment info"
    fi
    exit 1
fi
echo "ASCENT conda environment created successfully"

# Activate environment and install packages
echo "Activating ASCENT environment..."
if ! eval "$(conda shell.bash hook)"; then
    echo "ERROR: Failed to set conda shell hook"
    exit 1
fi
if ! conda activate ascent; then
    echo "ERROR: Failed to activate ascent environment"
    if ! conda info --envs; then
        echo "WARNING: Failed to get conda environment info"
    fi
    exit 1
fi
echo "ASCENT conda environment activated successfully"

# Verify environment is active
if [[ "$CONDA_DEFAULT_ENV" != "ascent" ]]; then
    echo "ERROR: Failed to activate ascent environment"
    echo "Current environment: $CONDA_DEFAULT_ENV"
    if ! conda info --envs; then
        echo "WARNING: Failed to get conda environment info"
    fi
    exit 1
fi
echo "Environment verification successful: $CONDA_DEFAULT_ENV"

echo "Installing Python packages from requirements.txt..."
# Install requirements with error handling
if ! python -m pip install -r requirements.txt; then
    echo "ERROR: Failed to install required packages"
    exit 1
fi

# Install ffmpeg
echo "Installing ffmpeg..."
if ! conda install -c conda-forge ffmpeg -y; then
    echo "WARNING: Failed to install ffmpeg, continuing..."
else
    echo "ffmpeg installed successfully"
fi

# Try to run pyfibers_compile (skip if not available)
echo "Checking for pyfibers_compile..."
if command -v pyfibers_compile &> /dev/null; then
    echo "Running pyfibers_compile..."
    if ! pyfibers_compile; then
        echo "WARNING: pyfibers_compile failed, continuing..."
    else
        echo "pyfibers_compile completed successfully"
    fi
else
    echo "pyfibers_compile not found, skipping..."
fi

echo "Docker installation complete!"
echo "Current conda environment: $CONDA_DEFAULT_ENV"
echo "Python location: $(which python)"
echo "Python version: $(python --version)"
echo "Conda info:"
if ! conda info; then
    echo "WARNING: Failed to get conda info"
fi
echo "Installed packages:"
if ! python -m pip list; then
    echo "WARNING: Failed to list installed packages"
fi

# Create necessary directories
echo "Creating necessary directories..."
if ! mkdir -p bin samples input config/user/runs config/user/sims; then
    echo "ERROR: Failed to create necessary directories"
    exit 1
fi
echo "Directories created successfully"

echo "ASCENT Docker installation completed successfully!"
