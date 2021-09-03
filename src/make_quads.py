#!/opt/sct/python/envs/venv_sct/bin/python
#
# Load fmri space masks and create dorsal and ventral ROIs

###########
# From Baxter. Can't resolve differences in qform/sform
# so just ignoring (not using label info anyway)

import sys
import nibabel
import numpy
import scipy.ndimage

gm_file = sys.argv[1]
# label_file = sys.argv[2]

# Load images
gm = nibabel.load(gm_file)
# label = nibabel.load(label_file)

# Verify that geometry matches
# if not (label.get_qform() == gm.get_qform()).all():
#     raise Exception('GM/LABEL mismatch in qform')
# if not (label.get_sform() == gm.get_sform()).all():
#     raise Exception('GM/LABEL mismatch in sform')
# if not (label.affine == gm.affine).all():
#     raise Exception('GM/LABEL mismatch in affine')
# if not label.header.get_data_shape() == gm.header.get_data_shape():
#     raise Exception('GM/LABEL mismatch in data shape')    

# Verify that orientation is RPI (as SCT calls it) or LAS (as nibabel calls it)
ort = nibabel.aff2axcodes(gm.affine)
if not ort == ('L', 'A', 'S'):
    raise Exception('GM image orientation is not nibabel LAS')

# Split GM into horns, slice by slice at center of mass
gm_data = gm.get_data()
gm_data[gm_data>0] = 1
dims = gm.header.get_data_shape()
if not (dims[2]<dims[0] and dims[2]<dims[1]):
    raise Exception('Third dimension is not slice dimension?')

nslices = dims[2]
horn_data = numpy.zeros(dims)

for s in range(nslices):
    
    slicedata = numpy.copy(gm_data[:,:,s])
    quadrants = numpy.zeros(dims[0:2])
    
    x = scipy.ndimage.center_of_mass(slicedata)
    
    if numpy.isnan(x[1]):
        print("empty slice")
    else:
        com = [int(round(x)) for x in scipy.ndimage.center_of_mass(slicedata)]

        # Label quadrants. For correct data orientation, these are
        #    1 - left ventral
        #    2 - right ventral
        #    3 - left dorsal
        #    4 - right dorsal

        ########### This is where quadrants are defined
        quadrants[com[0]+1:,com[1]+1:] = 1 # Old: quadrants[com[0]+1:,com[1]+1:] = 1
        quadrants[:com[0],com[1]+1:] = 2 # Old: quadrants[:com[0],com[1]+1:] = 2
        quadrants[com[0]+1:,:com[1]] = 3
        quadrants[:com[0],:com[1]] = 4

        # Set centerline values to zero
        ########### This is where to get rid of central 'lines'
        # slicedata[com[0]:com[0]+1,:] = 0 ###### Baxter's
        # slicedata[:,com[1]:com[1]+1] = 0 ###### Baxter's

        # slicedata[com[0]-4:com[0]+4,:] = 0 ###### FOR MFFE RESOLUTION
        # slicedata[:,com[1]:com[1]+1] = 0 ###### FOR MFFE RESOLUTION

        # slicedata[com[0]-2:com[0]+2,:] = 0 ###### FOR FUNC RESOLUTION
        # slicedata[:,com[1]:com[1]+1] = 0 ###### FOR FUNC RESOLUTION

        # To get rid of horizontal line, only keep the one below:
        slicedata[com[0]-1:com[0]+2,:] = 0

        # Label the four horns
        horn_data[:,:,s] = numpy.multiply(slicedata,quadrants)

horn = nibabel.Nifti1Image(horn_data,gm.affine,gm.header)
nibabel.save(horn,'quads.nii.gz')

# Mask labels by gray matter and write to file
# label_data = label.get_data()
# gm_inds = gm_data>0
# gm_data[gm_inds] = label_data[gm_inds]
# gmmasked = nibabel.Nifti1Image(gm_data,gm.affine,gm.header)
# nibabel.save(gmmasked,'fmri_moco_GMlabeled.nii.gz')

# Label by level and horn:
#    301 - C3, left ventral
#    302 - C3, right ventral
#    etc
# label_data = numpy.multiply(label_data,horn_data>0)
# horn_data = numpy.multiply(horn_data,label_data>0)
# hornlevel_data = 100*label_data + horn_data
# hornlevel = nibabel.Nifti1Image(hornlevel_data,gm.affine,gm.header)
# nibabel.save(hornlevel,'fmri_moco_GMcutlabel.nii.gz')
