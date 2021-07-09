#!/bin/bash -x

. /home/ccp_hcp/CCP_HCP/source_ccp/mylib/myfunctions.sh 		# to .lib?

#################### FUNCTIONS ####################
# print help
function usage () {
#    echo -e "TO DO: edit this help\n\n"
    echo -e "./01_wrapper.sh"
    echo -e "\t-h --help\t\t- prints help"
    echo -e "\t-f --InFile\t\t- configuration file\n\n"
}

#################### COMMAND LINE OPTIONS AND CONFIGURATION FILES ####################
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -f | --InFile) #dicoms
            CONFIG="$(dirname $VALUE)/$(basename $VALUE)"
	    ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

################ ENVIRONMENT/OTHER VARIABLES SETUP #######################
# Source environment for dicom conversion
export CONFIG
# read these from configuration file
export IN_DIR=$(get_value "IN_DIR" "${CONFIG}")
export OUT_DIR=$(get_value "OUT_DIR" "${CONFIG}")
export SUB_ID=$(get_value "SUB_ID" "${CONFIG}")

# check folders
if [ ! -d "$IN_DIR" ]; then
  echo -e "ERROR\t:\t${IN_DIR} (input directory) doesn't exist. Please, specify a valid input directory"
  usage
  exit 1
fi

if [ -d "${OUT_DIR}" ]; then #folder exists

	if ask_confirmation "## Directory ${OUT_DIR} already exists. Overwrite?[y/n]"; then
        	echo "Will overwrite $OUT_DIR"
		rm -rf $OUT_DIR
  	 else
        	echo "Stopping execution"
        	exit 1
   	fi
else # folder doesn't exist

	if ask_confirmation "## Folder doesn't exist. Create ${PWD}/${OUT_DIR}?[y/n]"; then
                echo "Creating output folder ${PWD}/${OUT_DIR}"
        else
                echo "Stopping execution"
                exit 1
        fi
fi

OUT_DIR="${OUT_DIR}/${SUB_ID}/unprocessed/3T"
mkdir -p $OUT_DIR

### generate and submit the PBS job.sh

TFILE=$(mktemp)
cp stroop005.batch ${TFILE}
echo "${CCP_HOME}/batch_scripts/02_dcm2nii.sh > \${PBS_O_WORKDIR}/outfile_stroop.log" >> ${TFILE}

cp "${TFILE}" "${PWD}/job.batch"
rm -rf ${TFILE}

chmod 755 "${PWD}/job.batch"

qsub "${PWD}/job.batch"
echo "PBS job sent"

exit 0
