
#!/usr/bin/env bash

# BPJS Registration Analysis Setup Script
echo "🏥 Setting up BPJS Registration Analysis Environment..."
echo "=================================================="

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check Python version
python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "✅ Python version: $python_version"



# Detect available python command
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "❌ Python is not installed or not in PATH. Please install Python 3.8+ and add to PATH."
    exit 1
fi

# Create virtual environment in .venv if not exists
if [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment in .venv..."
    $PYTHON_CMD -m venv .venv
else
    echo "📦 Virtual environment .venv already exists."
fi

# Activate virtual environment (cross-platform, Git Bash/Windows/Linux/Mac)
echo "🔧 Activating virtual environment..."
if [ -f ".venv/Scripts/activate" ]; then
    # Windows (Git Bash, CMD, PowerShell)
    ACTIVATE_PATH=".venv/Scripts/activate"
elif [ -f ".venv/bin/activate" ]; then
    # Linux/Mac
    ACTIVATE_PATH=".venv/bin/activate"
else
    echo "❌ Virtual environment activation script not found in .venv/Scripts/activate or .venv/bin/activate."
    echo "Try recreating with: $PYTHON_CMD -m venv .venv"
    exit 1
fi

# Only source if running in bash or compatible shell
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
    source "$ACTIVATE_PATH"
    echo "✅ Virtual environment activated."
else
    echo "⚠️  Please activate the environment manually: source $ACTIVATE_PATH"
fi

# Upgrade pip
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo "📚 Installing Python packages..."
pip install -r requirements.txt

# Download NLTK data
echo "📖 Downloading NLTK data..."
python3 -c "
import nltk
try:
    nltk.download('punkt', quiet=True)
    nltk.download('stopwords', quiet=True)
    nltk.download('vader_lexicon', quiet=True)
    print('✅ NLTK data downloaded successfully')
except Exception as e:
    print(f'⚠️  NLTK download warning: {e}')
"

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p data
mkdir -p models
mkdir -p reports
mkdir -p logs

# Create .env template file
echo "🔐 Creating environment template..."
cat > .env.template << EOL
# Database Configuration
DB_HOST=192.168.11.5
DB_USER=rsds_db
DB_PASS=rsdsD4t4b4s3
DB_NAME=rsds_db
DB_PORT=3306

# Application Settings
DEBUG=False
LOG_LEVEL=INFO
EOL

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.template .env
    echo "📝 Created .env file from template"
    echo "⚠️  Please update .env file with your database credentials"
fi

# Create project structure info
echo "📋 Creating project structure..."
cat > PROJECT_STRUCTURE.md << EOL
# BPJS Registration Analysis Project Structure

## Main Project Structure
- \`data/\` - Data files and exports
- \`models/\` - Saved ML models
- \`reports/\` - Generated analysis reports
- \`logs/\` - Application logs
- \`.venv/\` - Python virtual environment
- \`bpjs patient/\` - Main application directory

## BPJS Patient Application Structure
- \`bpjs patient/backend/\` - Backend API and services
  - \`app/\` - Application core modules
  - \`models/\` - Database and ML models
  - \`services/\` - Business logic services
  - \`utils/\` - Utility functions
- \`bpjs patient/frontend/\` - Frontend React application
  - \`src/\` - Source code
  - \`public/\` - Static assets
- \`bpjs patient/config/\` - Configuration files
- \`bpjs patient/docker/\` - Docker configuration
- \`bpjs patient/docs/\` - Documentation
- \`bpjs patient/scripts/\` - Utility scripts

## Configuration Files
- \`requirements.txt\` - Python dependencies
- \`.env\` - Environment variables (database credentials)
- \`setup.sh\` - Setup script for environment
- \`run_*.sh\` - Run scripts for different services

## Usage
1. Run setup: \`bash setup.sh\`
2. Jupyter Notebook: \`./run_jupyter.sh\`
3. Streamlit App: \`./run_streamlit.sh\`
EOL

# Create run scripts
echo "🚀 Creating run scripts..."


# Jupyter run script (Windows compatible)
cat > run_jupyter.sh << EOL
#!/bin/bash
# Windows/Linux compatible activation
if [ -f ".venv/Scripts/activate" ]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi
jupyter notebook
EOL

# Streamlit run script (Windows compatible)
cat > run_streamlit.sh << EOL
#!/bin/bash
# Windows/Linux compatible activation
if [ -f ".venv/Scripts/activate" ]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi
streamlit run streamlit_app.py
EOL

# Make run scripts executable
chmod +x run_jupyter.sh
chmod +x run_streamlit.sh

# Create systemd service file (optional)
cat > bpjs_streamlit.service << EOL
[Unit]
Description=BPJS Registration Analysis Streamlit App
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/.venv/bin"
ExecStart=$(pwd)/.venv/bin/streamlit run streamlit_app.py --server.port 8501
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Create backup script
cat > backup_data.sh << EOL
#!/bin/bash
# Backup script for BPJS analysis data
timestamp=\$(date +"%Y%m%d_%H%M%S")
mkdir -p backups
tar -czf backups/bpjs_backup_\$timestamp.tar.gz data/ models/ reports/ .env
echo "Backup created: backups/bpjs_backup_\$timestamp.tar.gz"
EOL

chmod +x backup_data.sh

# Test basic Python imports
echo "🔍 Testing Python environment..."
$PYTHON_CMD -c "
try:
    import pandas as pd
    import numpy as np
    import streamlit as st
    print('✅ Core libraries imported successfully')
    print('✅ Environment setup completed')
except ImportError as e:
    print(f'❌ Import error: {e}')
    print('⚠️  Some packages may not be installed correctly')
except Exception as e:
    print(f'❌ Environment test error: {e}')
"

# Final setup message
echo ""
echo "🎉 Setup completed successfully!"
echo "=================================================="
echo ""
echo "📋 Next steps:"
echo "1. Update .env file with your database credentials"
echo "2. Run Jupyter notebook: ./run_jupyter.sh"
echo "3. Run Streamlit app: ./run_streamlit.sh"
echo ""
echo "📚 Available commands:"
echo "- Start Jupyter: ./run_jupyter.sh"
echo "- Start Streamlit: ./run_streamlit.sh"
echo "- Backup data: ./backup_data.sh"
echo ""
echo "🌐 Streamlit app will be available at: http://localhost:8501"
echo "📊 Jupyter notebook will open in your browser"
echo ""
echo "📁 Project structure created in PROJECT_STRUCTURE.md"
echo ""

echo "⚠️  To run Python in a new shell, activate the environment with:"
if [[ -f ".venv/Scripts/activate" ]]; then
    echo "   Windows: .venv\\Scripts\\activate.bat"
    echo "   Git Bash: source .venv/Scripts/activate"
elif [[ -f ".venv/bin/activate" ]]; then
    echo "   Linux/Mac: source .venv/bin/activate"
else
    echo "   (activation file not found, ensure .venv was created successfully)"
fi
echo ""
echo "🔄 Virtual environment is active in this script, but you need to reactivate in new shells."