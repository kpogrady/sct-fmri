# MODIFIED VERSION FOR LUMBAR CORD
# Create CSF mask


mkdir csfmask
cd csfmask
cp ../fmri_moco_mean_seg.nii.gz .

sct_create_mask -i ../fmri_moco_mean.nii.gz -p centerline,fmri_moco_mean_seg.nii.gz \
-o fmri_mask_25mm.nii.gz -size 25mm -f cylinder

#split mean image into 14 slices as separate files
fslmaths ../fmri_moco_mean.nii.gz fmri_moco_mean.nii.gz -odt float
fslsplit fmri_moco_mean.nii.gz fmri_moco_mean -z

fslsplit fmri_moco_mean_seg.nii.gz fmri_moco_mean_seg -z
fslsplit fmri_mask_25mm.nii.gz fmri_mask_25mm -z

for g in `seq -f '%02g' 0 13`; do

# For more CSF, decrease this number
fslmaths fmri_moco_mean00${g}.nii.gz -thrp 60 -sub fmri_moco_mean_seg00${g}.nii.gz \
-mas fmri_mask_25mm00${g}.nii.gz tmp_im${g}.nii.gz

# For more CSF, decrease this number
fslmaths tmp_im${g}.nii.gz -thrp 20 -bin -ero tmp_im${g}_2.nii.gz # orig

fslmaths fmri_moco_mean_seg00${g}.nii.gz -mul -1 -add 1 tmp_mask${g}.nii.gz
fslmaths tmp_im${g}_2.nii.gz -mas tmp_mask${g}.nii.gz tmp_im${g}_3.nii.gz

done

fslmerge -z fmri_csf.nii.gz `ls tmp_im??_3.nii.gz`

fslmaths fmri_moco_mean_seg.nii.gz -dilF -mul -1 -add 1 \
-ero -ero -ero -ero  -ero -ero ../fmri_notspine.nii.gz

mv fmri_csf.nii.gz ../

cd ..; rm -r csfmask/

