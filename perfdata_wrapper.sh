#!/bin/bash
#----------------------------------------------------------------------
# IBM Confidential
# OCO Source Materials
#
# (C) Copyright IBM Corporation 2018.
#
# The source code for this program is not published or otherwise
# divested of its trade secrets, irrespective of what has been
# deposited with the U.S. Copyright Office.
#----------------------------------------------------------------------

set -x

SERVICE="$1"
START_TIME="$2"
END_TIME="$3"

BASELINE="${SERVICE}-baseline.csv"
SUMMARY="${SERVICE}-summary.csv"

CURRENT_DIR="$(cd $(dirname "$0"); pwd -P)"

HOST="$(hostname -f)"
TARGET_NODE="$(kubectl get pods -o wide | grep ${SERVICE} | awk '{print $7}')"

sudo ssh -tt root@${TARGET_NODE} 'bash -s' <<ENDSSH
cd /usr/perfdata
# We always want to generate a summary.
touch ${BASELINE}
/usr/perfdata/perfdatareport.sh ${SERVICE} ${START_TIME} ${END_TIME} || true
scp ${SUMMARY} root@${HOST}:${CURRENT_DIR}
rm -f ${BASELINE}
rm -f ${SUMMARY}
exit 0
ENDSSH