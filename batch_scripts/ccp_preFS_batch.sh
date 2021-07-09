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
#echo -e "SETUP SCRIPT\t:\t${SETUP}\n"
. ${CCP_HOME}/setup/setup_hcp.sh	# sources variables for HCP Pipelines


StudyFolder=$(get_value "STUDY_FOLDER" "${CONFIG}")
Subjlist=$(get_value "SUBJLIST" "${CONFIG}")
#EnvironmentScript=$(get_value "ENVIRONMENT_SCRIPT" "${CONFIG}" )
PRINTCOM=$(get_value "PRINTCOM" "${CONFIG}" )


echo -e "CONFIG FILE\t:\t${CONFIG}"
echo -e "STUDY FOLDER\t:\t${StudyFolder}"
echo -e "SUBJ LIST\t:\t${Subjlist}"
echo -e "PRINTCOM\t:\t${PRINTCOM}"
echo ""

######################################### DO WORK ##########################################

for Subject in $Subjlist ; do
 
 echo $Subject

  # Input Images
  # Detect Number of T1w Images
  numT1ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep T1w_MPR | wc -l`
  echo "Found ${numT1ws} T1w Images for subject ${Subject}"
  T1wInputImages=""
  i=1
  while [ $i -le $numT1ws ] ; do
    T1wInputImages=`echo "${T1wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR${i}/${Subject}_3T_T1w_MPR${i}.nii.gz@"`
    i=$(($i+1))
  done

  # Detect Number of T2w Images
  numT2ws=`ls ${StudyFolder}/${Subject}/unprocessed/3T | grep T2w_SPC | wc -l`
  echo "Found ${numT2ws} T2w Images for subject ${Subject}"
  T2wInputImages=""
  i=1
  while [ $i -le $numT2ws ] ; do
    T2wInputImages=`echo "${T2wInputImages}${StudyFolder}/${Subject}/unprocessed/3T/T2w_SPC${i}/${Subject}_3T_T2w_SPC${i}.nii.gz@"`
    i=$(($i+1))
  done

  # Readout Distortion Correction:
  AvgrdcSTRING=$(get_value "AVGRDC_STRING" "${CONFIG}")

  #   Variables related to using Siemens specific Gradient Echo Field Maps
  MagnitudeInputName=$(get_value "MAGNITUDE_INPUT_NAME" "${CONFIG}")
  PhaseInputName=$(get_value "PHASE_INPUT_NAME" "${CONFIG}")  
  if [[ "${MagnitudeInputName}" != "NONE" ]]; then
  	MagnitudeInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${MagnitudeInputName}"
  	PhaseInputName="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${PhaseInputName}"
  fi


  TE=$(get_value "TE" "${CONFIG}")


  #   Variables related to using Spin Echo Field Maps
  SpinEchoPhaseEncodeNegative=$(get_value "SPIN_ECHO_NEG" "${CONFIG}")
  SpinEchoPhaseEncodePositive=$(get_value "SPIN_ECHO_POS" "${CONFIG}")
  if [[ "${SpinEchoPhaseEncodePositive}" != "NONE" ]]; then  
  	SpinEchoPhaseEncodeNegative="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${SpinEchoPhaseEncodeNegative}"
  	SpinEchoPhaseEncodePositive="${StudyFolder}/${Subject}/unprocessed/3T/T1w_MPR1/${SpinEchoPhaseEncodePositive}"
  fi

  # Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples)
  DwellTime=$(get_value "DWELL_TIME" "${CONFIG}")	# 0.000580002668012

  # Spin Echo Unwarping Direction
  # Note: +x or +y are not supported. For positive values, do not include the + sign
  SEUnwarpDir=$(get_value "SE_UNWARP_DIR" "${CONFIG}")	# "x"

  # Topup Configuration file
  TopupConfig=$(get_value "TOPUP_CONFIG" "${CONFIG}")

  # General Electric stuff
  GEB0InputName=$(get_value "GEB0_INPUT_NAME" "${CONFIG}")

  # Templates
  T1wTemplate="${HCPPIPEDIR_Templates}/MNI152_T1_0.7mm.nii.gz" #Hires T1w MNI template
  T1wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T1_0.7mm_brain.nii.gz" #Hires brain extracted MNI template
  T1wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz" #Lowres T1w MNI template
  T2wTemplate="${HCPPIPEDIR_Templates}/MNI152_T2_0.7mm.nii.gz" #Hires T2w MNI Template
  T2wTemplateBrain="${HCPPIPEDIR_Templates}/MNI152_T2_0.7mm_brain.nii.gz" #Hires T2w brain extracted MNI Template
  T2wTemplate2mm="${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz" #Lowres T2w MNI Template
  TemplateMask="${HCPPIPEDIR_Templates}/MNI152_T1_0.7mm_brain_mask.nii.gz" #Hires MNI brain mask template
  Template2mmMask="${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz" #Lowres MNI brain mask template

  # Structural Scan Settings (set all to NONE if not doing readout distortion correction)
  # The values set below are for the HCP Protocol using the Siemens Connectom Scanner
  T1wSampleSpacing=$(get_value "T1W_SAMPLE_SPACING" "${CONFIG}") #DICOM field (0019,1018) in s or "NONE" if not used
  T2wSampleSpacing=$(get_value "T2W_SAMPLE_SPACING" "${CONFIG}") #DICOM field (0019,1018) in s or "NONE" if not used
  UnwarpDir=$(get_value "UNWARP_DIR" "${CONFIG}") # z appears to be best for Siemens Gradient Echo Field Maps or "NONE" if not used

  # Other Config Settings
  BrainSize=$(get_value "BRAIN_SIZE" "${CONFIG}") #BrainSize in mm, 150 for humans
  FNIRTConfig="${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf" #FNIRT 2mm T1w Config

  # GradientDistortionCoeffs="${HCPPIPEDIR_Config}/coeff_SC72C_Skyra.grad" #Location of Coeffs file or "NONE" to skip
  GradientDistortionCoeffs=$(get_value "GRADIENT_DISTORTION_COEFFS" "${CONFIG}") # Set to NONE to skip gradient distortion correction

${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
      --path="$StudyFolder" \
      --subject="$Subject" \
      --t1="$T1wInputImages" \
      --t2="$T2wInputImages" \
      --t1template="$T1wTemplate" \
      --t1templatebrain="$T1wTemplateBrain" \
      --t1template2mm="$T1wTemplate2mm" \
      --t2template="$T2wTemplate" \
      --t2templatebrain="$T2wTemplateBrain" \
      --t2template2mm="$T2wTemplate2mm" \
      --templatemask="$TemplateMask" \
      --template2mmmask="$Template2mmMask" \
      --brainsize="$BrainSize" \
      --fnirtconfig="$FNIRTConfig" \
      --fmapmag="$MagnitudeInputName" \
      --fmapphase="$PhaseInputName" \
      --echodiff="$TE" \
      --SEPhaseNeg="$SpinEchoPhaseEncodeNegative" \
      --SEPhasePos="$SpinEchoPhaseEncodePositive" \
      --echospacing="$DwellTime" \
      --seunwarpdir="$SEUnwarpDir" \
      --t1samplespacing="$T1wSampleSpacing" \
      --t2samplespacing="$T2wSampleSpacing" \
      --unwarpdir="$UnwarpDir" \
      --gdcoeffs="$GradientDistortionCoeffs" \
      --avgrdcmethod="$AvgrdcSTRING" \
      --topupconfig="$TopupConfig" \
      --printcom=$PRINTCOM

  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo -e "set -- --path=${StudyFolder}\n \
      --subject=${Subject}\n \
      --t1=${T1wInputImages}\n \
      --t2=${T2wInputImages}\n \
      --t1template=${T1wTemplate}\n \
      --t1templatebrain=${T1wTemplateBrain}\n \
      --t1template2mm=${T1wTemplate2mm}\n \
      --t2template=${T2wTemplate}\n \
      --t2templatebrain=${T2wTemplateBrain}\n \
      --t2template2mm=${T2wTemplate2mm}\n \
      --templatemask=${TemplateMask}\n \
      --template2mmmask=${Template2mmMask}\n \
      --brainsize=${BrainSize}\n \
      --fnirtconfig=${FNIRTConfig}\n \
      --fmapmag=${MagnitudeInputName}\n \
      --fmapphase=${PhaseInputName}\n \
      --fmapgeneralelectric=${GEB0InputName}\n \
      --echodiff=${TE}\n \
      --SEPhaseNeg=${SpinEchoPhaseEncodeNegative}\n \
      --SEPhasePos=${SpinEchoPhaseEncodePositive}\n \
      --echospacing=${DwellTime}\n \
      --seunwarpdir=${SEUnwarpDir}\n \
      --t1samplespacing=${T1wSampleSpacing}\n \
      --t2samplespacing=${T2wSampleSpacing}\n \
      --unwarpdir=${UnwarpDir}\n \
      --gdcoeffs=${GradientDistortionCoeffs}\n \
      --avgrdcmethod=${AvgrdcSTRING}\n \
      --topupconfig=${TopupConfig}\n \
      --printcom=${PRINTCOM}\n"

  echo ". ${SETUP}"

  chmod -R 775 ${StudyFolder}/${Subject}

done
