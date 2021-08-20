#!/usr/bin/env bash
#
# Primary entrypoint for our pipeline. This just parses the command line 
# arguments, exporting them in environment variables for easy access
# by other shell scripts later. Then it calls the rest of the pipeline.
#
# Example usage:
# 
# sct-fmri.sh --fmri_niigz /path/to/image.nii.gz

# This statement at the top of every bash script is helpful for debugging
echo Running $(basename "${BASH_SOURCE}")

# Initialize defaults for any input parameters where that seems useful. These
# values will be used if a parameter is not specified on the command line.
export masksize = 30
export label_info="UNKNOWN SCAN"
export out_dir=/OUTPUTS

# Parse input options
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        
        --fmri_niigz)
            # Take a single 4D spinal cord fMRI as input. This
            # is expected to be the fully qualified path and filename.
            export fmri_niigz="$2"; shift; shift ;;

        --masksize)
            # Size in mm of the fmri mask to create
            export masksize="$2"; shift; shift ;;

        --label_info)
            # Labels from XNAT that we will use to label the QA PDF,
            # e.g. "PROJECT SUBJECT SESSION SCAN"
            export label_info="$2"; shift; shift ;;

        --out_dir)
            # Where outputs will be stored. Also the working directory
            export out_dir="$2"; shift; shift ;;

        *)
            echo "Input ${1} not recognized"
            shift ;;

    esac
done


# Now that we have all the inputs stored in environment variables, call the
# main pipeline. We run it in xvfb so that we have a virtual display available.
xvfb-run -n $(($$ + 99)) -s '-screen 0 1600x1200x24 -ac +extension GLX' \
    bash main.sh
