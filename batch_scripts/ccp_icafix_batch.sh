#!/bin/bash -xe

. ${CCP_HOME}/mylib/myfunctions.sh
#################### FUNCTIONS ####################
# print help
function usage () {
#   echo -e "TO DO: edit this help\n\n"
    echo -e "./test_icafix_batch.sh.sh"
    echo -e "\t-h --help \t\t- prints help"
    echo -e "\t-f --InFile \t\t- configuration file\n\n"
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


# Source environment for HCP
. ${CCP_HOME}/setup/setup_hcp.sh      # sources variables for HCP Pipelines
#module load R

FixScript=${FSL_FIXDIR}/hcp_fix
StudyFolder=$(get_value "STUDY_FOLDER" "${CONFIG}")
Subject=$(get_value "SUBJECT_NAME" "${CONFIG}")

echo -e "CONFIG FILE\t:\t${CONFIG}"
echo -e "STUDY FOLDER\t:\t${StudyFolder}"
echo -e "SUBJECT NAME\t:\t${Subject}"


####
bandpass=$(get_value "BANDPASS" ${CONFIG})
TrainingData=$(get_value "TRAINING_DATA" ${CONFIG})
bold=$(get_value "BOLD_NAME" ${CONFIG})
InputDir="${StudyFolder}/${Subject}/MNINonLinear/Results/${bold}" # run over unprocessed input better?
InputFile="${InputDir}/${bold}.nii.gz"



#if use FSL_QUEUE; then
#	"QUEUE="-q hcp_priority.q"
#	queuing_command="${FSLDIR}/bin/fsl_sub ${QUEUE}"
#	${queuing_command} ${FixScript} ${InputFile} ${bandpass} ${TrainingData}

#else

echo -e "COMMAND\t:\t${FixScript} ${InputFile} ${bandpass} ${TrainingData}"
${FixScript} ${InputFile} ${bandpass} ${TrainingData}

#fi


echo -e "set -- --path=$StudyFolder\n \
      --subject=$Subject"
