#/bin/bash -x

export CCP_TEMPLATES="${CCP_HOME}/templates"
echo -e "Templates\t:\t${CCP_TEMPLATES}"
#################################

# print help
function usage () {
    echo -e "./launch_structural.sh"
    echo -e "\t-h --help \t\t- prints help\n\n"
    echo -e "\t-s --Subjects \t\t- subjects file (mandatory)\n\n"
    echo -e "\t-b --Block \t\t- Step of HCP Pipelines to run\t:\tpreFS, FS, postFS (mandatory)\n\n"
    echo -e "\t-d --DataDir \t\t- HCP Study dir containing the subjects folders (mandatory)\n\n"
    echo -e "\t-q --Queue \t\t- Submit to cluster (optional).\n\n"


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
        -s | --Subjects)
            list_subjects=$VALUE
	    ;;
        -b | --Block) #dicoms
            block=$VALUE
            ;;
        -d | --DataDir)
            outputdir="$(dirname $VALUE)/$(basename $VALUE)"
	    outputdir=${outputdir%/}
            ;;
	-q | --Queue)
            qsub_flag=1
	    ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done


if [[ -z ${list_subjects} || -z ${block} || -z ${outputdir} ]] ; then
	echo -e "ERROR\t\t:\t missing parameter(s)"
	usage
	exit
fi

WD=$(pwd)
echo -e "working dir\t:\t${WD}"
echo -e "Subjects\t:\t${list_subjects}"
echo -e "Block\t\t:\t${block}"
echo -e "Output dir\t:\t${outputdir}"
echo ""



########

while read SUBJECT; do

	if [ "${SUBJECT}" != "" ]; then

		if [ ! -d "${SUBJECT}" ]; then
	                echo -e "----Creating experiment folder ${SUBJECT}----"
	                mkdir -p "${SUBJECT}"
	        fi

		if [ ! -e "${SUBJECT}/config_structural_spinechoFM.cfg" ]; then
			cp "${CCP_TEMPLATES}/config_structural_spinechoFM.cfg" "${SUBJECT}"
		fi

		sed -i "s@STUDYFOLDERPLACEHOLDER@${outputdir}@g" "${SUBJECT}/config_structural_spinechoFM.cfg"
		sed -i "s/SUBJECTPLACEHOLDER/${SUBJECT}/g" "${SUBJECT}/config_structural_spinechoFM.cfg"


		if [ ! -d "${SUBJECT}/${block}_log" ]; then
  			echo -e "----Creating log file for ${block}----"
			mkdir -p "${SUBJECT}/${block}_log"
		fi

		cp "${CCP_TEMPLATES}/batch_${block}.pbs" "${SUBJECT}"
		sed -i "s/SUBJECTPLACEHOLDER/${SUBJECT}/g" "${SUBJECT}/batch_${block}.pbs"

		cd ${SUBJECT}
		echo -e "In subject ${SUBJECT} folder"


		chmod 755 "batch_${block}.pbs" "config_structural_spinechoFM.cfg"

		if [  ! -z "${qsub_flag}" ]; then
			echo -e "Submitting job ${SUBJECT}/batch_${block}.pbs from directory $(pwd)"
			qsub "batch_${block}.pbs"
		fi

		cd $WD
		echo -e "Back to working dir ${WD}"

	fi # SUBJECT


done < ${list_subjects}
