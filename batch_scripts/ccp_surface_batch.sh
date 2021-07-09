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
PRINTCOM=$(get_value "PRINTCOM" "${CONFIG}" )


echo -e "CONFIG FILE\t:\t${CONFIG}"
echo -e "STUDY FOLDER\t:\t${StudyFolder}"
echo -e "SUBJ LIST\t:\t${Subjlist}"
echo -e "PRINTCOM\t:\t${PRINTCOM}"





##################################### DO STUFF
Tasklist=$(get_value "TASK_LIST" "${CONFIG}")

for Subject in $Subjlist ; do
  echo $Subject

  for fMRIName in $Tasklist ; do
    echo "  ${fMRIName}"
    LowResMesh="32" #Needs to match what is in PostFreeSurfer, 32 is on average 2mm spacing between the vertices on the midthickness
    FinalfMRIResolution=$(get_value "FINAL_FMRI_RESOLUTION" "${CONFIG}") #Needs to match what is in fMRIVolume, i.e. 2mm for 3T HCP data and 1.6mm for 7T HCP data
    SmoothingFWHM=$(get_value "SMOOTHING_FWHM" "${CONFIG}") #Recommended to be roughly the grayordinates spacing, i.e 2mm on HCP data 
    GrayordinatesResolution=$(get_value "GRAYORDINATES_RESOLUTION" "${CONFIG}") #Needs to match what is in PostFreeSurfer. 2mm gives the HCP standard grayordinates space with 91282 grayordinates.  Can be different from the FinalfMRIResolution (e.g. in the case of HCP 7T data at 1.6mm)
    # RegName="MSMSulc" #MSMSulc is recommended, if binary is not available use FS (FreeSurfer)
    RegName=$(get_value "REG_NAME" "${CONFIG}")

    ${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh \
      --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=$fMRIName \
      --lowresmesh=$LowResMesh \
      --fmrires=$FinalfMRIResolution \
      --smoothingFWHM=$SmoothingFWHM \
      --grayordinatesres=$GrayordinatesResolution \
      --regname=$RegName

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

      echo -e "set -- --path=$StudyFolder\n \
      --subject=$Subject\n \
      --fmriname=$fMRIName\n \
      --lowresmesh=$LowResMesh\n \
      --fmrires=$FinalfMRIResolution\n \
      --smoothingFWHM=$SmoothingFWHM\n \
      --grayordinatesres=$GrayordinatesResolution\n \
      --regname=$RegName"

   done
   chmod -R 775 ${StudyFolder}/${Subject}
done
