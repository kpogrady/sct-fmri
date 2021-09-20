# 18 Oct 2019
# R01 dataset and lumbar spine

# Running RETROICOR using Baxter's python scripts

# BPR - deleted all prep stuff. It should be done earlier already

# BPR - Get to the working directory where all our files are
cd "${out_dir}"

# BPR - We want parse_physlog.py in the PATH env variable so we don't 
#       have to know it here. Two options: one, add the path in the 
#       Singularity file. Two, chosen here, move the python scripts to
#       the src dir which is already in the path. Oh, and third option,
#       update the PATH in entrypoint.sh, but that seems a little less
#       clean.
#       Note that I also updated all python files to get the executable
#       from the environment instead of hard-coding its path - their 
#       first line is now
#           #!/usr/bin/env python
# 496Hz is sampling rate of 3T-A and 3T-B, hard coded, for physio data
parse_physlog.py fmri.log 496 fmri.dcm

# BPR - In this case I updated the Singularity file to add the afni 
#       stuff to the path. Also, we'll use the original code in the
#       external dir instead of the copy in retroicor_lumbar dir 
#       (which is now removed)
RetroTS.py \
    -r physlog_respiratory.csv \
    -c physlog_cardiac.csv -p 496 -n 1 \
    -v `cat vat.txt` \
    -cardiac_out 0 -prefix ricor

cleanup_physlog.py

# BPR - note that this script makes a lot of assumptions about filenames
regress.py

mv ffmri_moco.nii.gz ../proc/fmri_rc.nii.gz
mv vat.txt ../proc/
rm *dcm *log *nii.gz
