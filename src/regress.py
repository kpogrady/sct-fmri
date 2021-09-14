#!/usr/bin/env python
#
# Generate confound regressors and remove, slice by slice

import nibabel
import nitime
import numpy

ricor_file = 'ricor.csv'
fmri_file = 'func_moco.nii.gz'
csf_file = 'func_csf.nii.gz'
notspine_file = 'func_notspine.nii.gz'
mocoX_file = 'func_moco_params_X.nii.gz'
mocoY_file = 'func_moco_params_Y.nii.gz'

numPCs = 5

# Get moco params + derivs and reshape/combine to time x param x slice
mocoX_data = nibabel.load(mocoX_file).get_data()
mocoY_data = nibabel.load(mocoY_file).get_data()
mocoX_data = numpy.transpose(mocoX_data,(3,0,2,1))
mocoY_data = numpy.transpose(mocoY_data,(3,0,2,1))
moco_data = numpy.squeeze( numpy.concatenate((mocoX_data,mocoY_data),1) )
moco_derivs = numpy.diff(moco_data,n=1,axis=0,prepend=0)
moco_data = numpy.concatenate((moco_data,moco_derivs),1)
print('moco size %d,%d,%d' % moco_data.shape)

# Cardiac/respiratory. We apply the same ones to all slices, assuming
# 3D fmri acquisition sequence. ricor_file is the appropriate output
# from RetroTS.py
ricor_data = numpy.genfromtxt(ricor_file,delimiter=',')
print('Found phys data size %d,%d' % ricor_data.shape)

# fmri time series data
fmri_img = nibabel.load(fmri_file)
dims = fmri_img.header.get_data_shape()
nslices = dims[2]
nvols = dims[3]

# CSF and NOTSPINE mask images in fmri space
csf_img = nibabel.load(csf_file)
notspine_img = nibabel.load(notspine_file)

# Verify that all images have the same geometry
if not ( (csf_img.affine==notspine_img.affine).all() and
         (csf_img.affine==fmri_img.affine).all() ):
    raise Exception('affine mismatch in image files')

# Check that slice axis is third and get number of slices
if not (dims[2]<dims[0] and dims[2]<dims[1]):
    raise Exception('Third dimension is not slice dimension?')
print('Found %d slices, %d vols' % (nslices,nvols))

# Get fmri data and reshape to inslice x thruslice x time. Reslice
# appears to copy. Make empty for filtered data
print('Loading fmri')
fmri_data = fmri_img.get_data();
rfmri_data = numpy.reshape(fmri_data,(dims[0]*dims[1],nslices,nvols),order='F')
frfmri_data = numpy.zeros(rfmri_data.shape)

# Binarize and reshape CSF and NOTSPINE masks
print('Confound masks')
csf_mask = numpy.greater(csf_img.get_data(),0)
rcsf_mask = numpy.reshape(csf_mask,(dims[0]*dims[1],nslices),order='F')
ns_mask = numpy.greater(notspine_img.get_data(),0)
rns_mask = numpy.reshape(ns_mask,(dims[0]*dims[1],nslices),order='F')


print('Slicewise correction')
for s in range(nslices):

    # This slice fmri data
    sfmri_data = rfmri_data[:,s,:].T

    # Noise data, time x voxel
    csf_data = numpy.copy(rfmri_data[rcsf_mask[:,s],s,:]).T
    ns_data = numpy.copy(rfmri_data[rns_mask[:,s],s,:]).T

    # Normalize - subtract time mean, time sd = 1. Drop constant-valued voxels
    numpy.seterr(invalid='ignore')
    csf_data -= numpy.mean(csf_data,0)
    csf_data /= numpy.std(csf_data,0)
    csf_data = csf_data[:,numpy.logical_not(numpy.isnan(numpy.std(csf_data,0)))]
    ns_data -= numpy.mean(ns_data,0)
    ns_data /= numpy.std(ns_data,0)
    ns_data = ns_data[:,numpy.logical_not(numpy.isnan(numpy.std(ns_data,0)))]
    numpy.seterr(invalid='warn')

    # Get largest eigenvalue components and pct variance explained
    csf_PCs,csf_S,V = numpy.linalg.svd(csf_data, full_matrices=False)
    csf_var = numpy.square(csf_S)
    csf_var = csf_var / sum(csf_var)
    ns_PCs,ns_S,V = numpy.linalg.svd(ns_data, full_matrices=False)
    ns_var = numpy.square(ns_S)
    ns_var = ns_var / sum(ns_var)

    # Combine and rescale the desired confound regressors
    confounds = numpy.hstack((ricor_data,moco_data[:,:,s],
                    csf_PCs[:,0:numPCs],ns_PCs[:,0:numPCs]))
    confounds -= numpy.mean(confounds,0)
    confounds /= numpy.std(confounds,0)
    confounds1 = numpy.hstack((confounds,numpy.ones((nvols,1))))

    # Remove confounds from this slice (except the constant) and store
    #  doc notation: b = ax,   x = numpy.linalg.lstsq(a,b)
    #   my notation: y = xb,   b = numpy.linalg.lstsq(x,y)
    beta1,sumresid,rank,svals = numpy.linalg.lstsq(confounds1,sfmri_data,rcond=None)
    residual = sfmri_data - numpy.matmul(confounds,beta1[0:-1,:])
    frfmri_data[:,s,:] = residual.T

# Reshape filtered fmri and save
ffmri_data = numpy.reshape(frfmri_data,dims,order='F')
ffmri_img = nibabel.Nifti1Image(ffmri_data,fmri_img.affine,fmri_img.header)
nibabel.save(ffmri_img,'f'+fmri_file)

# Test re-save of re-reshaped original data to verify correct reshaping
#test_data = numpy.reshape(rfmri_data,dims,order='F')
#test_img = nibabel.Nifti1Image(test_data,fmri_img.affine,fmri_img.header)
#nibabel.save(test_img,'test.nii.gz')