#!/bin/bash
LOCALHOST=${TEST_URL}
CODE=`wget --server-response ${LOCALHOST}"/services/EchoProxy" 2>&1 | awk '/^  HTTP/{print $2}'`;
if [ ${CODE} -eq "200" ] ; then
  exit 0
else
  exit 1
fi
