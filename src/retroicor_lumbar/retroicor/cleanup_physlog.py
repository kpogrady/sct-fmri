#!/opt/sct/python/envs/venv_sct/bin/python
# 
# Get RetroTS output into friendly csv format

import numpy

ricor_file_in = 'ricor.slibase.1D'
ricor_file_out = 'ricor.csv'
ricor_data = numpy.genfromtxt(ricor_file_in,skip_header=5,skip_footer=0)
numpy.savetxt(ricor_file_out,ricor_data,delimiter=',')