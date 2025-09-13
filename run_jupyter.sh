#!/bin/bash
# Windows/Linux compatible activation
if [ -f ".venv/Scripts/activate" ]; then
    source .venv/Scripts/activate
else
    source .venv/bin/activate
fi
jupyter notebook
