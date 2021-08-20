# SCT fMRI processing

## Inputs

See `test_container.sh` for an example run command.

    --fmri_niigz     4D spinal cord fMRI, fully qualified path and filename
    --masksize       Size of mask to create in mm
    --label_info     Text to label the PDF, e.g. from XNAT project/subject
    --out_dir        Outputs directory (and working directory)


## Pipeline

See `main.sh`.


## Outputs

    fmri0.nii.gz              First volume of fMRI
    
    fmri_mask??.nii.gz        Created analysis mask
    
    fmri_centerline.nii.gz    Cord centerline
    fmri_centerline.csv
    
    fmri_moco.nii.gz          Moco outputs
    fmri_moco_mean.nii.gz
    moco_params.tsv
    moco_params_x.nii.gz
    moco_params_y.nii.gz
