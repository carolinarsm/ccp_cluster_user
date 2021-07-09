#!/bin/bash


#################
# FUNCTIONS
#################


#===  FUNCTION  ================================================================
# NAME        : CONTAINS_SUBSTRING
# DESCRIPTION : check if a target string contains substrings from an array string
# PARAMETER 1 : string
# PARAMETER 2 : array of strings (substrings)
# RETURNS     : 1 if a string of the array is substring of the target string, else 0
#===============================================================================

contains_substring_BAK () {

    string_aux=$(echo $1 | awk '{print tolower($0)}')

    echo ''
    echo -e "\tString\t:\t$1"
    echo -e "\tList\t:\t$2"

    for substring in $2 ; do

        if [[ "$string_aux" =~ "$substring" ]]; then
            echo -e "\tRESULT\t:\t'$1' contains '$substring'"
            eval "$3='1'"
            return 1

        else
            echo -e "\tRESULT\t:\t'$1' does not contain '$substring'."
        fi

    done

    eval "$3='0'"
    return 0
}


#===  FUNCTION  =================================================================
# NAME        : RETURN_MATCH_SUBSTRING
# DESCRIPTION : check if a target string contains substrings from an array string
# PARAMETER 1 : string
# PARAMETER 2 : array of strings (substrings)
# RETURNS     : idem as above, but also echoes the value of the matching substring
#=================================================================================

return_match_string () {

    string_aux=$(echo $1 | awk '{print tolower($0)}')

#    echo ''
#    echo -e "\tString\t:\t$1"
#    echo -e "\tList\t:\t$2"

    for substring in $2 ; do
        if contains_substring "${string_aux}" "${substring}"; then
            eval "$3=$substring"
            return 0
        fi
    done

    eval "$3='meh'"
}


#===  FUNCTION  ================================================================
# NAME        : SERIES_POLARITY
# DESCRIPTION : receives a series name and checks if its polarity is RL or LR
# PARAMETER 1 : series name (STRING)
# RETURNS     : echo the polarity string (_RL or _LR)
#===============================================================================

series_polarity () {
    result=''
    return_match_string $1 "_lr _rl _ap _pa" result > /dev/null 2>&1 # dump all the standard output, otherwise is written to a variable and returned
    result=$(echo $result | awk '{print toupper($0)}')
    echo "$result"


}
#===  FUNCTION  ================================================================
# NAME        : IS_SBREF
# DESCRIPTION : checks if a bold series is an sbref serie
# PARAMETER 1 : series name (STRING)
# RETURNS     : true or false (1 or 0)
#===============================================================================

is_sbref () {

   if contains_substring $1 "_sbref"; then
	#echo "true"
	return 0
   else
	#echo "false"
	return 1
   fi

}

#===  FUNCTION  =========================================================================================
# NAME        : EXTENSION_EXISTS
# DESCRIPTION : given a string and a folder, checks if a file containing  the string exists in the folder
# PARAMETER 1 :
# PARAMETER 2 :
# RETURNS     :
#========================================================================================================

extension_exists () {
    count=$(find $2 -maxdepth 1 -name "*.${1}" | wc -l)
    if [ "$count" == "0"  ]; then # no file with that extension found in folder $2
        echo "false"
        return 0

    else
        echo "true"
        return 1
    fi
}

#===  FUNCTION  ================================================================
# NAME        : FIND_NII
# DESCRIPTION : return the name of a .nii.gz file
# PARAMETER 1 : folder name (path)
# RETURNS     : name of .nii files
#===============================================================================
find_nii () { #returns string with file names, Correct this (array-string stuff)
    filename=$(find "${1}" -maxdepth 1 -type f -name '*.nii')
    echo "$filename"
}

#===  FUNCTION  ================================================================
# NAME        : FIND_NIIGZ
# DESCRIPTION : return the name of a .nii.gz file
# PARAMETER 1 : folder name (path)
# RETURNS     : name of .nii.gz files
#===============================================================================
find_niigz () { #returns string with file names, Correct this (array-string stuff)
    filename=$(find "${1}" -maxdepth 1 -type f -name '*.nii.gz')
    echo "$filename"
}




#===  FUNCTION  ================================================================
# NAME        : READ_CONFIG (not using this function)
# DESCRIPTION :
# PARAMETER 1 :
# PARAMETER 2 :
# RETURNS     :
#===============================================================================
read_config () { # reads a configuration file with lines: name=value

	i=0
	while read line; do
		#echo $line
		if [[ "$line" =~ ^[^#]*= ]]; then

        		name[i]=$(echo $line | cut -d'=' -f 1)
        		value[i]=$(echo $line | cut -d'=' -f 2)
        		((i++))
		fi
	done < ${1}

	echo -e "${name[@]}###${value[@]}"

	return 0
}

#===  FUNCTION  ================================================================
# NAME        : GET_VALUE
# DESCRIPTION :
# PARAMETER 1 :
# PARAMETER 2 :
# RETURNS     :
#===============================================================================
# Usage:VALUE=$(get_value "IN_DIR" "preprocess_config.txt")

get_value () {

        if [[ -f $2 ]]; then
                name_value=$(grep -w $1 $2)
                value=$(echo "${name_value}" | cut -d'=' -f 2)
                echo $value
                return 0
        else
                echo "ERROR: file '$2' does not exist"
                exit 1 #make this a return and test in the main script!
	fi

}


#===  FUNCTION  ================================================================
# NAME        : ASK_CONFIRMATION
# DESCRIPTION : asks a yes/no question 
# PARAMETER 1 : question
# PARAMETER 2 : 
# RETURNS     : 0 if YES, 1 if NO
#===============================================================================

ask_confirmation () {

	YES_WORDS="y yes"
	echo -e "$1 : " 
	read answer

	if contains_substring "${answer}" "${YES_WORDS}"; then
        	echo -e "Your answer was positive: $answer"
		return 0
	else
        	echo -e "Your answer was negative: $answer"
                return 1
	fi

}





#===  FUNCTION  ================================================================
# NAME        : 
# DESCRIPTION : 
# PARAMETER 1 : 
# PARAMETER 2 : 
# RETURNS     :
#===============================================================================

contains_substring () {

    string_aux=$(echo $1 | awk '{print tolower($0)}')

    # $1: substring
    # $2: DISCARD_WORDS="localizer bias aahscout scout nav norm"


#    echo ''
#    echo -e "\tString\t:\t$1"
#    echo -e "\tList\t:\t$2"

    for substring in $2 ; do

        if [[ "$string_aux" =~ "$substring" ]]; then
            #echo -e "\tRESULT\t:\t'$1' contains '$substring'"
            return 0

        else
            #echo -e "\tRESULT\t:\t'$1' does not contain '$substring'."
        continue
        fi
    done
    return 1
}




#===  FUNCTION  ================================================================
# NAME        : 
# DESCRIPTION : 
# PARAMETER 1 : 
# PARAMETER 2 : 
# RETURNS     :
#===============================================================================



#===  FUNCTION  ================================================================
# NAME        : 
# DESCRIPTION : 
# PARAMETER 1 : 
# PARAMETER 2 : 
# RETURNS     :
#===============================================================================

