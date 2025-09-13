# BPJS Registration Analysis Project Structure

## Main Project Structure
- `data/` - Data files and exports
- `models/` - Saved ML models
- `reports/` - Generated analysis reports
- `logs/` - Application logs
- `.venv/` - Python virtual environment
- `bpjs patient/` - Main application directory

## BPJS Patient Application Structure
- `bpjs patient/backend/` - Backend API and services
  - `app/` - Application core modules
  - `models/` - Database and ML models
  - `services/` - Business logic services
  - `utils/` - Utility functions
- `bpjs patient/frontend/` - Frontend React application
  - `src/` - Source code
  - `public/` - Static assets
- `bpjs patient/config/` - Configuration files
- `bpjs patient/docker/` - Docker configuration
- `bpjs patient/docs/` - Documentation
- `bpjs patient/scripts/` - Utility scripts

## Configuration Files
- `requirements.txt` - Python dependencies
- `.env` - Environment variables (database credentials)
- `setup.sh` - Setup script for environment
- `run_*.sh` - Run scripts for different services

## Usage
1. Run setup: `bash setup.sh`
2. Jupyter Notebook: `./run_jupyter.sh`
3. Streamlit App: `./run_streamlit.sh`
