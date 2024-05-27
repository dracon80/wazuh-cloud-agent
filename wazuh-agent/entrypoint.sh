#!/bin/bash

##############################################################################
# Author: Nathan Dennis
# Description: Runs the Wazuh Agent within the Docker Instance
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