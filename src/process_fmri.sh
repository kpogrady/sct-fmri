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

# segment motion corrected fMRI 
# (outputs are fmri_moco_mean_seg.nii.gz and fmri_moco_mean_gmseg.nii.gz)
sct_deepseg_sc -i fmri_moco_mean.nii.gz -c t2s
sct_deepseg_gm -I fmri_moco_mean.nii.gz

# run mask_csf_lumbar.sh script to generate csf and not spine masks for noise regression
mask_csf_lumbar.sh

# at this stage, want the option to QC cord, GM, csf, and not spine masks and upload corrected segmentations

# Run RETROICOR .sh script
retroicor_lumbar.sh

# Separate GM seg into quadrants
# unsure how to call this function: make_quads.py fmri_moco_mean_gmseg.nii.gz

 

