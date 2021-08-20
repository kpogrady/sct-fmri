#!/usr/bin/env bash

echo Running $(basename "${BASH_SOURCE}")

# Check our python
pythontest.py

# Copy input files to the working directory (out_dir)
copy_files.sh

# fmri processing
process_fmri.sh

# Make PDF for QA. A PDF is required for all XNAT pipelines
make_pdf.sh
