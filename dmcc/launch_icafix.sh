#!/bin/bash -xe


export CCP_TEMPLATES="${CCP_HOME}/templates"
echo -e "Templates\t:\t${CCP_TEMPLATES}"
#################################

# print help
function usage () {
#    echo -e "TO DO: edit this help\n\n"
    echo -e "./launch_icafix.sh"
    echo -e "\t-h --help \t\t- prints help\n\n."
    echo -e "\t-s --Subjects \t\t- subjects list file (mandatory)\n\n"
    echo -e "\t-d --DataDir \t\t- HCP Study dir containing the subjects folders (mandatory)\n\n"
    echo -e "\t-q --Queue \t\t- Submit to cluster (optional)\n\n"
}


#################### COMMAND LINE OPTIONS AND CONFIGURATION FILES ####################
while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    VALUE=$(echo "$1" | awk -F= '{print $2}')
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
	-s | --Subjects)
            subjects_list=$VALUE
            ;;
	-t | --TaskList)
            task_list=$VALUE
            ;;
	-d | --DataDir)
            data_dir="$(dirname "$VALUE")/$(basename "$VALUE")"
            data_dir=${data_dir%/}
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


if [[ -z ${subjects_list} || -z ${task_list} || -z ${data_dir} ]] ; then
	echo -e "ERROR\t\t:\t missing parameter(s)"
	usage
	exit
fi

#WD=$(pwd)

echo -e "Data dir\t:\t${data_dir}"
echo -e "Subjects\t:\t${subjects_list}"
echo ""


################
while read SUBJECT; do


	if [ "${SUBJECT}" != "" ]; then


		if [ ! -e "${task_list}" ] || [ ! -f "${task_list}" ]; then
			echo -e "ERROR: ${task_list} doesn't exist or is not a regular file."
			exit
        	fi

		while read TASK; do

			if [ "${TASK}" != "" ]; then

#				out_dir="${data_dir}/${SUBJECT}/MNINonLinear/Results/${TASK}"
				out_dir="${data_dir}/${SUBJECT}"

				config_file="$(pwd)/${SUBJECT}_${TASK}_icafix.cfg"
				job_file="$(pwd)/${SUBJECT}_${TASK}_icafix.pbs"

	                        # input data folder doesn't exist
        	                if [ ! -d "${data_dir}/${SUBJECT}/MNINonLinear/Results/${TASK}" ]; then # or TASK.nii.gz doesn't exist?
					echo -e "WARNING: folder ${out_dir} doesn't exist. Cannot run ICA-FIX for this series.\n"
				else


					cp "${CCP_TEMPLATES}/config_icafix.cfg" "${config_file}"
					sed -i "s@STUDYFOLDERPLACEHOLDER@${data_dir}@g" "${config_file}"
					sed -i "s/SUBJECTPLACEHOLDER/${SUBJECT}/g" "${config_file}"
					sed -i "s/BOLDPLACEHOLDER/${TASK}/g" "${config_file}"


					cp "${CCP_TEMPLATES}/batch_icafix.pbs" "${job_file}"
					sed -i "s/SUBJECTPLACEHOLDER/${SUBJECT}/g" "${job_file}"
					sed -i "s@CONFIGPLACEHOLDER@${config_file}@g" "${job_file}"

                                	if [  ! -z "${qsub_flag}" ]; then
                                        	echo -e "Submitting job ${job_file} from directory $(pwd) to PBS queue."
						chmod 755 && qsub "${job_file}"
					fi


				fi
			fi
		done <"${task_list}"

	fi
done <"${subjects_list}"
