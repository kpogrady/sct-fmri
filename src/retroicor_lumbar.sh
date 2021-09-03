# 18 Oct 2019
# R01 dataset and lumbar spine

# Running RETROICOR using Baxter's python scripts
# Installing pydicom in the specific python instance that SCT uses
# /Users/combesa/spinalcordtoolbox/python/envs/venv_sct/bin/python -m pip install pydicom
# /Users/combesa/spinalcordtoolbox/python/envs/venv_sct/bin/python -m pip install nitime

# 6 Feb 2020
# If got rid of the DCM file to save space, need the VAT (in text file).
# Look into parse_physlog.py to run without section where DCM file is read;
# then go to next step RetroTS using .txt file as input.

subj=$1
mypy="/Users/kristinogrady/sct_5.3.0/python/envs/venv_sct/bin/python"
rdir=$subj/retroicor
bax=/Users/kristinogrady/Documents/SpinalCordProjects/Lumbar_Cord_K01/Code/SCfMRI/baxter

mkdir -p $rdir
cp `ls $subj/orig/SCAN*.log` $rdir/func.log
cp `ls $subj/orig/*.DCM` $rdir/func.dcm
cp $subj/proc/*moco_params_x.nii.gz $rdir/func_moco_params_X.nii.gz
cp $subj/proc/*moco_params_y.nii.gz $rdir/func_moco_params_Y.nii.gz
cp $subj/proc/*moco.nii.gz $rdir/func_moco.nii.gz
cp $subj/proc/func_csf.nii.gz $rdir/func_csf.nii.gz
cp $subj/proc/func_notspine.nii.gz $rdir/func_notspine.nii.gz
cd $rdir

#496Hz is sampling rate of 3T-A and 3T-B, hard coded, for physio data
$mypy ${bax}/retroicor/parse_physlog.py func.log 496 func.dcm

$mypy ${bax}/afni/RetroTS.py \
-r physlog_respiratory.csv \
-c physlog_cardiac.csv -p 496 -n 1 \
-v `cat vat.txt` \
-cardiac_out 0 -prefix ricor

$mypy ${bax}/retroicor/cleanup_physlog.py

$mypy ${bax}/retroicor/regress.py

mv ffunc_moco.nii.gz ../proc/func_rc.nii.gz
mv vat.txt ../proc/
rm *dcm *log *nii.gz