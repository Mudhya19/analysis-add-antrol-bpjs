#!/bin/bash
# Backup script for BPJS analysis data
timestamp=$(date +"%Y%m%d_%H%M%S")
mkdir -p backups
tar -czf backups/bpjs_backup_$timestamp.tar.gz data/ models/ reports/ .env
echo "Backup created: backups/bpjs_backup_$timestamp.tar.gz"
