#!/usr/bin/env bash
#
# Use fsleyes to create a PDF QA report. This is entirely fidgety, but still
# is easier than doing it in Matlab.

echo Running $(basename "${BASH_SOURCE}")

# Work in output directory
cd ${out_dir}

# Binarize the mask and find its center of mass, as a starting point for
# slice placement in the visualization. Voxel coords
com=$(fslstats fmri_mask${masksize} -C)
XYZ=(${com// / })
X=$(printf '%.0f' ${XYZ[0]})
Y=$(printf '%.0f' ${XYZ[1]})

# Show each slice with the mask outline
nsl=$(fslval fmri_moco_mean.nii.gz dim3)
zoom=2000
for Z in $(seq -s ' ' -f '%03.0f' 1 $nsl); do

    echo "    Slice at $X $Y $Z"

    # Sleep before and after to avoid some kind of race condition or 
    # disk access delay when testing in docker:
    # SystemError: wxEntryStart failed, unable to initialize wxWidgets!
    sleep 1
    fsleyes render -of slice_${Z}.png \
        --scene ortho --voxelLoc $X $Y $Z \
        --xzoom $zoom --yzoom $zoom --zzoom $zoom \
        --layout horizontal --hideCursor --hidex --hidey \
        fmri_moco_mean --overlayType volume \
        fmri_mask${masksize} --overlayType label --lut random_big \
        --outline --outlineWidth 2
    sleep 1

done

# Combine into single image using ImageMagick
montage -mode concatenate slice_*.png \
    -tile 3x -quality 100 -background black -gravity center \
    -border 10 -bordercolor black page1.png

# Resize and add text annotations. We choose a large but not ridiculous
# pixel size for the full page.
convert \
    -size 2600x3365 xc:white \
    -gravity center \( page1.png -resize 2400x \) -composite \
    -gravity North -pointsize 48 -annotate +0+100 \
    "Mask on fmri_moco_mean" \
    -gravity SouthEast -pointsize 48 -annotate +100+100 "$(date)" \
    -gravity NorthWest -pointsize 48 -annotate +100+200 "${label_info}" \
    page1.png

# Convert to PDF
convert page1.png moco.pdf

# Clean up
rm page1.png slice_*.png
