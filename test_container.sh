#!/usr/bin/env bash

singularity run \
    --cleanenv --contain \
    --bind INPUTS:/INPUTS \
    --bind OUTPUTS:/OUTPUTS \
    --bind OUTPUTS:/tmp \
    test.simg \
    --fmri_niigz /INPUTS/fmri.nii.gz \
    --masksize 30 \
    --label_info "TEST SCAN" \
    --out_dir /OUTPUTS


exit 0


# Or shell in. Remember this if working on code in cwd:
#   export PATH=/wkdir/src:$PATH
singularity shell \
    --cleanenv --contain \
    --bind INPUTS:/INPUTS \
    --bind OUTPUTS:/OUTPUTS \
    --bind OUTPUTS:/tmp \
    --bind $(pwd):/wkdir \
    test.simg
