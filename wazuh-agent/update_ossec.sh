#/bin/bash

##############################################################################
# Author: Nathan Dennis
# Description: Reads in the configuration file config and dynamically creates
#   variables that are then replaced in the source ossec.conf file. The
#   ossec.conf file is then copied into /var/ossec/etc/ossec.conf ready for
#   the wazuh agent to be started within the container.
#
# MIT License
#
# Copyright (c) [Year] Nathan Dennis
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
##############################################################################


##############################################################################
## Validates that the value provided does not contain any special characters
## that could potentionally be used as an injection attack
##
## Parameters
## $1 = The key name for the config pair that is to be validated
## $2 = The value of the config pair to be validated
##############################################################################
validate_config_value() {
    local key="$1"
    local value="$2"
    local invalid_characters=$(echo "$value" | grep -o '[^a-zA-Z0-9_./~-]')

    if [[ -n "$invalid_characters" ]]; then
        print_error "Invalid characters found in config key:'$key'"
        echo "  Invalud value: $value" >&2
        echo "  Invalid characters found: $invalid_characters" >&2
        echo "  Acceptable characters: '[^a-zA-Z0-9_./-]'" >&2
        exit 1
    fi
}
##############################################################################
## Reads each line of the config file and loads the Key/Value pair as a
## dynamic named variable if they are on the provided white list.
##
## Parameters
## $1 = The path to a config file that should be read into variables
## $2 = An array of white listed key names. Any keys found in the file that
##      are not in this array are ignored.
##############################################################################
# Reads in a config file and creates global variables based on the content of the config file
read_config_file() {
    local config_file="$1"
    shift
    local keys=("$@")

    shopt -s nocasematch

    # Check that the config file exists
    if ! [ -e "$config_file" ]; then
        print_error "configfile $config_file is not present"
        exit 1
    fi

    # Check that a list of expected keys have been provided
    if [ -z "$keys" ]; then
        print_error "expected_keys has not been set."
        exit 1
    fi

    # Read the properties file and assign variables
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        if [[ -z "$key" || "$key" == "#"* ]]; then
            continue
        fi

        # Check if the key is in the expected_keys array
        if [[ " ${keys[@]} " =~ " $key " ]]; then
            # Check for invalid characters in the value
            validate_config_value $key $value

            # Assign the value to the variable

            #Check to see if the value is true or false and if so assign a boolean
            if [[ "$value" == "true" ]]; then
                value=true
            fi
            if [[ "$value" == "false" ]]; then
                value=false
            fi

            declare -g "$key"="$value"
            print_debug "Key:$key value:$value"
        else
            print_debug "Ignoring unrecognized key: $key"
        fi
    done < "$config_file"

}
##############################################################################
## Echo a formated debug message to std out. Uses the variable $LOGGING to
## determin if the message should be displayed.
##
## Parameters
## $1 = The message to display
##############################################################################
print_debug(){
    shopt -s nocasematch

    if [[ "$LOGGING" == "verbose" ]]; then
        echo "DEBUG  : $1"
    fi
}
##############################################################################
## Echo a formated info message to std out. Uses the variable $LOGGING to
## determin if the message should be displayed.
##
## Parameters
## $1 = The message to display
##############################################################################
print_info(){
    shopt -s nocasematch

    if [[ "$LOGGING" == "info" || "$LOGGING" == "verbose" ]]; then
        echo "INFO   : $1"
    fi
    
}
##############################################################################
## Echo a formated warning message to std out.
##
## Parameters
## $1 = The message to display
##############################################################################
print_warning(){
    echo "WARNING: $1"
}
##############################################################################
## Echo a formated error message to error out.
##
## Parameters
## $1 = The message to display
##############################################################################
print_error(){
    echo "ERROR  : $1" >&2
}

source="/wazuh-agent/ossec-tmp.conf"
target="/var/ossec/etc/ossec.conf"

token_host="__MANAGER_HOST__"
token_port="__MANAGER_PORT__"
token_protocol="__MANAGER_PROTOCOL__"
token_microsoft_tenant_id="__MICROSOFT_TENANT_ID__"
token_microsoft_client_id="__MICROSOFT_CLIENT_ID__"
token_microsoft_client_secret="__MICROSOFT_CLIENT_SECRET__"

expected_keys=("MANAGER_HOST" "MANAGER_PORT" "MANAGER_PROTOCOL" "MICROSOFT_TENANT_ID" "MICROSOFT_CLIENT_ID" "MICROSOFT_CLIENT_SECRET" "LOGGING")
config_file="/wazuh-agent/config"

read_config_file "$config_file" "${expected_keys[@]}"

# Check the return status of read_config_file
if [ $? -ne 0 ]; then
    exit 1
fi

# Check if Required config values have been assigned 
if [ -z "$MANAGER_HOST" ]; then
    print_error "MANAGER_HOST is not set in config file"
    exit 1
fi

# Assign default values to any config values that have not been set
: ${MANAGER_PORT:="1514"}
: ${MANAGER_PROTOCOL:="tcp"}

#make a copy of the file
cp "/wazuh-agent/ossec.conf" $source

print_debug "Replacing Tokens within ossec.conf"
sed -i "s/$token_host/$MANAGER_HOST/g" $source
sed -i "s/$token_port/$MANAGER_PORT/g" $source
sed -i "s/$token_protocol/$MANAGER_PROTOCOL/g" $source
sed -i "s/$token_microsoft_tenant_id/$MICROSOFT_TENANT_ID/g" $source
sed -i "s/$token_microsoft_client_id/$MICROSOFT_CLIENT_ID/g" $source
sed -i "s/$token_microsoft_client_secret/$MICROSOFT_CLIENT_SECRET/g" $source

print_debug "Copy $source $target"
cp $source $target

print_debug "Starting Wazuh Agent"
result=$(/var/ossec/bin/wazuh-control start 2>&1)

exit_status=$?

# Check the exit status the agent starting
if [ $exit_status -eq 0 ]; then
    tail -F "/var/ossec/logs/ossec.log"
else
    print_error "$result - code: $exit_status"
    exit 1
fi