#/bin/bash -x


export CCP_TEMPLATES="${CCP_HOME}/templates"
echo -e "Templates\t:\t${CCP_TEMPLATES}"
#################################

# print help
function usage () {
#    echo -e "TO DO: edit this help\n\n"
    echo -e "./launch_functional.sh"
    echo -e "\t-h --help \t\t- prints help\n\n."
    echo -e "\t-s --Subjects \t\t- subjects list file (mandatory)\n\n"
    echo -e "\t-b --Block \t\t- Step of HCP Pipelines to run\t:\tvolume,surface (mandatory)\n\n"
    echo -e "\t-d --DataDir \t\t- HCP Study dir containing the subjects folders (mandatory)\n\n"
    echo -e "\t-q --Queue \t\t- Submit to cluster (optional)\n\n"

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

################
while read SUBJECT; do


	if [ "${SUBJECT}" != "" ]; then

		if [ ! -d "${SUBJECT}" ]; then
			echo -e "ERROR: Couldn't find folder ${WD}/${SUBJECT}."
			exit

		# if -e ?
		elif [ ! -e "${SUBJECT}/task_list.txt" ] && [ -f "${SUBJECT}/task_list.txt" ]; then
			echo -e "ERROR: Couldn't find ${WD}/${SUBJECT}/task_list.txt file."
			exit
        	fi


		if [ ! -e "${SUBJECT}/config_functional.cfg" ]; then
			cp "${CCP_TEMPLATES}/config_functional.cfg" "${SUBJECT}"
		fi

		sed -i "s@STUDYFOLDERPLACEHOLDER@${outputdir}@g" "${SUBJECT}/config_functional.cfg"
		sed -i "s/SUBJECTPLACEHOLDER/${SUBJECT}/g" "${SUBJECT}/config_functional.cfg"


		if [ ! -d "${SUBJECT}/${block}_log" ]; then
  			echo -e "----Creating log file for ${script}----"
			mkdir -p "${SUBJECT}/${block}_log"
		fi

		cp "${CCP_TEMPLATES}/batch_${block}.pbs" "${SUBJECT}"
		sed -i "s/SUBJECTPLACEHOLDER/${SUBJECT}/g" "${SUBJECT}/batch_${block}.pbs"

		cd ${SUBJECT}
		echo -e "In subject ${SUBJECT} folder"

		while read line; do

			if [ "${line}" != "" ]; then
				task=$(echo "${line}" | cut -d' ' -f1)
				pe=$(echo "${line}" | cut -d' ' -f2)

	                        # check that task hasn't been run
        	                if [ ! -d "${StudyFolder}/${task}" ]; then

                                	sed "s/TASKPLACEHOLDER/${task}/g" "config_functional.cfg" > "config_functional_${block}_${task}.cfg"
                                	sed -i "s/PHASEENCODINGPLACEHOLDER/${pe}/g" "config_functional_${block}_${task}.cfg"
                                	sed "s/${SUBJECT}\_${block}/${SUBJECT}\_${block}\_${task}/g" "batch_${block}.pbs" > "batch_${block}_${task}.pbs"
                                	sed -i "s/config\_functional/config\_functional\_${block}_${task}/g" "batch_${block}_${task}.pbs"

                                	chmod 755 "batch_${block}_${task}.pbs"

                                	if [  ! -z "${qsub_flag}" ]; then
                                        	echo -e "Submitting job ${SUBJECT}/batch_${block}_${task}.pbs from directory $(pwd) to PBS queue."
                                        	qsub "batch_${block}_${task}.pbs"
                                	fi
				else
                                       	echo -e "WARNING:"
                                       	echo -e "Folder ${StudyFolder}/${task} already exists. Will not overwrite."
                                        echo -e "To run this block again, remove all related content from T1w/xfms, MNINonLinear/xfms, MNINonLInear/Results first."

				fi
			fi

		done <task_list.txt

		rm "config_functional.cfg" "batch_${block}.pbs"

		cd $WD
		echo -e "Back to working dir ${WD}"

	fi # SUBJECT

done < ${list_subjects}
