#!/bin/bash

./update_ossec.sh

#Another command is being exec in the container
exec "$@"
