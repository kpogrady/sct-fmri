#!/usr/bin/env bash
#
# Copy input files to the working directory, with hard-coded
# filenames to simplify programming the pipeline

echo Running $(basename "${BASH_SOURCE}")

cp "${fmri_niigz}" "${out_dir}"/fmri.nii.gz
