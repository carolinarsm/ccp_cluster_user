#!/bin/bash 

. ${CCP_HOME}/mylib/myfunctions.sh
#################### FUNCTIONS ####################
# print help
function usage () {
#    echo -e "TO DO: edit this help\n\n"
    echo -e "./preprocess_data_01.sh"
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

################ ENVIRONMENT/OTHER VARIABLES SETUP #######################
# Source environment for dicom conversion
#SETUP=$(get_value "SETUP_HCP" "${CONFIG}")
#echo ""
#echo -e "SETUP SCRIPT\t:\t:${SETUP}\n"
. ${CCP_HOME}/setup/setup_hcp.sh      # sources variables for HCP Pipelines


StudyFolder=$(get_value "STUDY_FOLDER" "${CONFIG}")
Subjlist=$(get_value "SUBJLIST" "${CONFIG}")
#EnvironmentScript=$(get_value "ENVIRONMENT_SCRIPT" "${CONFIG}" )
PRINTCOM=$(get_value "PRINTCOM" "${CONFIG}" )


echo -e "CONFIG FILE\t:\t${CONFIG}"
echo -e "STUDY FOLDER\t:\t${StudyFolder}"
echo -e "SUBJ LIST\t:\t${Subjlist}"
echo -e "PRINTCOM\t:\t${PRINTCOM}"




########################################## INPUTS ############################################

#Scripts called by this script do assume they run on the outputs of the PreFreeSurfer Pipeline

######################################### DO WORK ############################################

for Subject in $Subjlist ; do
  echo $Subject

  #Input Variables
  SubjectID="$Subject" #FreeSurfer Subject ID Name
  SubjectDIR="${StudyFolder}/${Subject}/T1w" #Location to Put FreeSurfer Subject's Folder
  T1wImage="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T1wImageBrain="${StudyFolder}/${Subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz" #T1w FreeSurfer Input (Full Resolution)
  T2wImage="${StudyFolder}/${Subject}/T1w/T2w_acpc_dc_restore.nii.gz" #T2w FreeSurfer Input (Full Resolution)


 # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo -e "set -- --subject="$Subject"\n \
      --subjectDIR="$SubjectDIR"\n \
      --t1="$T1wImage"\n \
      --t1brain="$T1wImageBrain"\n \
      --t2="$T2wImage"\n \
      --printcom=$PRINTCOM"

  echo ". ${SETUP}"


  ${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh \
      --subject="$Subject" \
      --subjectDIR="$SubjectDIR" \
      --t1="$T1wImage" \
      --t1brain="$T1wImageBrain" \
      --t2="$T2wImage" \
      --printcom=$PRINTCOM
  chmod -R 775 ${StudyFolder}/${Subject}

done


