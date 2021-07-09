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

######################################### DO WORK ##########################################

Tasklist=$(get_value "TASK_LIST" "${CONFIG}")
PhaseEncodinglist=$(get_value "PHASE_ENCODING_LIST" "${CONFIG}") #x for RL, x- for LR, y for PA, y- for AP

for Subject in $Subjlist ; do
  echo $Subject

  i=1
  for fMRIName in $Tasklist ; do
    echo "  ${fMRIName}"
    UnwarpDir=`echo $PhaseEncodinglist | cut -d " " -f $i`
    fMRITimeSeries="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_${fMRIName}.nii.gz"
    fMRISBRef="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${Subject}_3T_${fMRIName}_SBRef.nii.gz" #A single band reference image (SBRef) is recommended if using multiband, set to NONE if you want to use the first volume of the timeseries for motion correction
    DwellTime=$(get_value "DWELL_TIME" "${CONFIG}") #Echo Spacing or Dwelltime of fMRI image, set to NONE if not used. Dwelltime = 1/(BandwidthPerPixelPhaseEncode * # of phase encoding samples): DICOM field (0019,1028) = BandwidthPerPixelPhaseEncode, DICOM field (0051,100b) AcquisitionMatrixText first value (# of phase encoding samples).  On Siemens, iPAT/GRAPPA factors have already been accounted for.   
    DistortionCorrection=$(get_value "DISTORTION_CORRECTION" "${CONFIG}") #FIELDMAP or TOPUP, distortion correction is required for accurate processing
    BiasCorrection=$(get_value "BIAS_CORRECTION" "${CONFIG}")
    SEPhaseEncodeNegative=$(get_value "SPIN_ECHO_NEG" "${CONFIG}")
    SEPhaseEncodePositive=$(get_value "SPIN_ECHO_POS" "${CONFIG}")
    SpinEchoPhaseEncodeNegative="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${SEPhaseEncodeNegative}" #For the spin echo field map volume with a negative phase encoding direction (LR in HCP data, AP in 7T HCP data), set to NONE if using regular FIELDMAP
    SpinEchoPhaseEncodePositive="${StudyFolder}/${Subject}/unprocessed/3T/${fMRIName}/${SEPhaseEncodePositive}" #For the spin echo field map volume with a positive phase encoding direction (RL in HCP data, PA in 7T HCP data), set to NONE if using regular FIELDMAP


    MagnitudeInputName=$(get_value "MAGNITUDE_INPUT_NAME" "${CONFIG}") #Expects 4D Magnitude volume with two 3D timepoints, set to NONE if using TOPUP
    PhaseInputName=$(get_value "PHASE_INPUT_NAME" "${CONFIG}") #Expects a 3D Phase volume, set to NONE if using TOPUP
    DeltaTE=$(get_value "DELTA_TE" "${CONFIG}") #2.46ms for 3T, 1.02ms for 7T, set to NONE if using TOPUP
    FinalFMRIResolution=$(get_value "FINAL_FMRI_RESOLUTION" "${CONFIG}") #Target final resolution of fMRI data. 2mm is recommended for 3T HCP data, 1.6mm for 7T HCP data (i.e. should match acquired resolution).  Use 2.0 or 1.0 to avoid standard FSL templates
    GradientDistortionCoeffs=$(get_value "GRADIENT_DISTORTION_COEFFS" "${CONFIG}") #Gradient distortion correction coefficents, set to NONE to turn off
    TopUpConfig=$(get_value "TOPUP_CONFIG" "${CONFIG}") #Topup config if using TOPUP, set to NONE if using regular FIELDMAP

    MCType=$(get_value "MC_TYPE" "${CONFIG}")


    ${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh \
      --path=$StudyFolder \
      --subject=$Subject \
      --fmriname=$fMRIName \
      --fmritcs=$fMRITimeSeries \
      --fmriscout=$fMRISBRef \
      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative \
      --SEPhasePos=$SpinEchoPhaseEncodePositive \
      --fmapmag=$MagnitudeInputName \
      --fmapphase=$PhaseInputName \
      --echospacing=$DwellTime \
      --echodiff=$DeltaTE \
      --unwarpdir=$UnwarpDir \
      --fmrires=$FinalFMRIResolution \
      --dcmethod=$DistortionCorrection \
      --gdcoeffs=$GradientDistortionCoeffs \
      --topupconfig=$TopUpConfig \
      --printcom=$PRINTCOM \
      --biascorrection=$BiasCorrection \
      --mctype=${MCType}


  # The following lines are used for interactive debugging to set the positional parameters: $1 $2 $3 ...

  echo -e "set -- --path=$StudyFolder\n \
      --subject=$Subject\n \
      --fmriname=$fMRIName\n \
      --fmritcs=$fMRITimeSeries\n \
      --fmriscout=$fMRISBRef\n \
      --SEPhaseNeg=$SpinEchoPhaseEncodeNegative\n \
      --SEPhasePos=$SpinEchoPhaseEncodePositive\n \
      --fmapmag=$MagnitudeInputName\n \
      --fmapphase=$PhaseInputName\n \
      --echospacing=$DwellTime\n \
      --echodiff=$DeltaTE\n \
      --unwarpdir=$UnwarpDir\n \
      --fmrires=$FinalFMRIResolution\n \
      --dcmethod=$DistortionCorrection\n \
      --gdcoeffs=$GradientDistortionCoeffs\n \
      --topupconfig=$TopUpConfig\n \
      --printcom=$PRINTCOM \
      --biascorrection=$BiasCorrection \
      --mctype=${MCType}"


  echo ". ${SETUP}"
    i=$(($i+1))

  done
  chmod -R 775 ${StudyFolder}/${Subject}
done
