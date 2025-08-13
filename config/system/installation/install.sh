#! /bin/bash
set -e

# Check if we're in a Docker container (non-interactive)
if [ -t 0 ]; then
    # Interactive mode - original behavior
    conda init
    CONDA_ENVPY=$(conda info --base)/envs/ascent/bin/python
    CONDA_BASE=$(conda info --base)/etc/profile.d/conda.sh
    source $CONDA_BASE
    conda create -n ascent python=3.11
    eval "$(conda shell.bash hook)"
    conda activate ascent
    $CONDA_ENVPY -m pip install -r requirements.txt
    conda install -c conda-forge ffmpeg
    pyfibers_compile

    echo
    # create shortcut
    read -p "Add ASCENT environment setup alias to '.bash_profile'? (recommended) [y/N] " yn
    case $yn in
        [Yy]* )
            echo "alias ascent_setup='source $CONDA_BASE; conda activate ascent; cd $PWD'" >> ~/.bash_profile
            echo "Added. Remember to run 'ascent_setup' to use (requires shell restart)."
            ;;
        [Nn]* ) echo "Not added";;
    esac
else
    # Non-interactive mode (Docker container)
    echo "Running in non-interactive mode (Docker container)"
    
    # Initialize conda
    echo "Initializing conda..."
    conda init bash
    
    # Source conda
    echo "Sourcing conda..."
    CONDA_BASE=$(conda info --base)/etc/profile.d/conda.sh
    if [ ! -f "$CONDA_BASE" ]; then
        echo "ERROR: conda.sh not found at $CONDA_BASE"
        exit 1
    fi
    source $CONDA_BASE
    
    # Check if ascent environment already exists
    if conda env list | grep -q "ascent"; then
        echo "ASCENT environment already exists, removing it..."
        conda env remove -n ascent -y
    fi
    
    # Create ascent environment
    echo "Creating ASCENT conda environment..."
    conda create -n ascent python=3.11 -y
    
    # Activate environment and install packages
    echo "Activating ASCENT environment..."
    eval "$(conda shell.bash hook)"
    conda activate ascent
    
    # Verify environment is active
    if [[ "$CONDA_DEFAULT_ENV" != "ascent" ]]; then
        echo "ERROR: Failed to activate ascent environment"
        echo "Current environment: $CONDA_DEFAULT_ENV"
        conda info --envs
        exit 1
    fi
    
    echo "Installing Python packages from requirements.txt..."
    # Install requirements with error handling
    if ! python -m pip install -r requirements.txt; then
        echo "ERROR: Failed to install required packages"
        exit 1
    fi
    
    # Install ffmpeg
    echo "Installing ffmpeg..."
    conda install -c conda-forge ffmpeg -y
    
    # Try to run pyfibers_compile (skip if not available)
    echo "Checking for pyfibers_compile..."
    if command -v pyfibers_compile &> /dev/null; then
        echo "Running pyfibers_compile..."
        pyfibers_compile
    else
        echo "pyfibers_compile not found, skipping..."
    fi
    
    echo "Docker installation complete!"
    echo "Current conda environment: $CONDA_DEFAULT_ENV"
    echo "Python location: $(which python)"
    echo "Installed packages:"
    python -m pip list
fi

exit 0
