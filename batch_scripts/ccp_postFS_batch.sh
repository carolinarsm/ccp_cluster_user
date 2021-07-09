#!/bin/bash -x

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




#Scripts called by this script do assume they run on the outputs of the FreeSurfer Pipeline

######################################### DO WORK ##########################################


for Subject in $Subjlist ; do
  echo $Subject

  #Input Variables
  SurfaceAtlasDIR="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
  GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/91282_Greyordinates"
  GrayordinatesResolutions=$(get_value "GRAYORDINATES_RESOLUTION" "${CONFIG}") #Usually 2mm, if multiple delimit with @, must already exist in templates dir
  HighResMesh="164" #Usually 164k vertices
  LowResMeshes="32" #Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
  SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
  FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
  ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
  # RegName="MSMSulc" #MSMSulc is recommended, if binary is not available use FS (FreeSurfer)
  RegName=$(get_value "REG_NAME" "${CONFIG}")


 ${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh \
      --path="$StudyFolder" \
      --subject="$Subject" \
      --surfatlasdir="$SurfaceAtlasDIR" \
      --grayordinatesdir="$GrayordinatesSpaceDIR" \
      --grayordinatesres="$GrayordinatesResolutions" \
      --hiresmesh="$HighResMesh" \
      --lowresmesh="$LowResMeshes" \
      --subcortgraylabels="$SubcorticalGrayLabels" \
      --freesurferlabels="$FreeSurferLabels" \
      --refmyelinmaps="$ReferenceMyelinMaps" \
      --regname="$RegName" \
      --printcom=$PRINTCOM

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

   echo -e "set -- --path="$StudyFolder"\n \
      --subject="$Subject"\n \
      --surfatlasdir="$SurfaceAtlasDIR"\n \
      --grayordinatesdir="$GrayordinatesSpaceDIR"\n \
      --grayordinatesres="$GrayordinatesResolutions"\n \
      --hiresmesh="$HighResMesh"\n \
      --lowresmesh="$LowResMeshes"\n \
      --subcortgraylabels="$SubcorticalGrayLabels"\n \
      --freesurferlabels="$FreeSurferLabels"\n \
      --refmyelinmaps="$ReferenceMyelinMaps"\n \
      --regname="$RegName"\n \
      --printcom=$PRINTCOM"

   echo ". ${SETUP}"
   chmod -R 775 ${StudyFolder}/${Subject}
done


