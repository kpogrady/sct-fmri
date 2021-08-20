#!/usr/bin/env bash

echo Running $(basename "${BASH_SOURCE}")

# Work in the output dir
cd "${out_dir}"

# Extract first fmri volume, find centerline, make fmri space mask
sct_image -keep-vol 0 -i fmri.nii.gz -o fmri0.nii.gz
sct_get_centerline -c t2s -i fmri0.nii.gz
mv fmri0_centerline.nii.gz fmri_centerline.nii.gz
mv fmri0_centerline.csv fmri_centerline.csv
sct_create_mask -i fmri0.nii.gz -p centerline,fmri_centerline.nii.gz \
    -size ${masksize}mm -o fmri_mask${masksize}.nii.gz

# fMRI motion correction
sct_fmri_moco -m fmri_mask${masksize}.nii.gz -i fmri.nii.gz 

