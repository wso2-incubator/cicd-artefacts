#!/bin/bash

# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------

# This script builds a zipped file of a WSO2 WUM supported product after applying the followings.
# If INITIAL_RUN,
#     1. WUM update.
#     2. Apply custom configurations using a configuration managemnt tool like Ansible or Puppet.
#     3. Copy the artifact(s) to the location(s).
#     4. Run the in-place updates tool.
# If not the INITIAL_RUN,
#     1. Apply custom configurations using a configuration managemnt tool like Ansible or Puppet.
#     2. Copy the artifact(s) to the location(s).
#     3. Run the in-place updates tool.
#
# Prerequisites
#   1. WUM 3.0.1 installed
#   2. Puppet 5.4.1 or higher installed
#   3. Puppet module configurations under the directory conf-home/modules/
#   4. Directory pre created with the module_name inside conf-home/script
#
# TODO: Add git support to clone the PUPPET modules

PRODUCT=${PRODUCT}
PRODUCT_VERSION=${VERSION}
CHANNEL="full"
INITIAL_RUN=false
CONF_LOCATION="${PUPPET_CONF_LOC}"
ARTIFACT_LOCATION=${ARTIFACT_LOC}
WORKING_DIRECTORY=$(pwd)
MODULE_PATH="${PUPPET_CONF_LOC}/modules"
ZIP_OUTPUT_LOCATION=${ZIP_OUTPUT_LOC}
DEPLOYMENT_PATTERN="ei_integrator"
WUM_USER=${WUM_USERNAME}
WUM_PASSWORD=${WUM_PASSWORD}
WUM_PRODUCT_HOME="${WUM_HOME}"
WUM=`which wum`
CP=`which cp`
MV=`which mv`
RM=`which rm`
UNZIP=`which unzip`
ZIP=`which zip`
PUPPET=`which puppet`
FAILED_WUM_UPDATE=10
FAILED_WUM_ADD=11
FAILED_INPLACE_UPDATES=12
FAILED_PUPPET_APPLY=13
FAILED_TO_MOVE_WUMMED_PRODUCT=14
FAILED_UNZIP=15
FAILED_RM_UNZIP=16
FAILED_ARTIFACT_APPLY=17

if [ -d "${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/" ];
then
   echo "Applying artifact(s) to the existing deployment pattern >> $DEPLOYMENT_PATTERN..."
else
   echo "Initial Run..."
   INITIAL_RUN=true
   mkdir ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/
fi

if $INITIAL_RUN ;
then
  ${WUM} init -u ${WUM_USER} -p ${WUM_PASSWORD} -v &>> wum.log

  # Add WUM product
  echo "Adding the product - ${PRODUCT}-${PRODUCT_VERSION}..." &>> wum.log
  ${WUM} add ${PRODUCT}-${PRODUCT_VERSION} -y  -v &>> wum.log
  if [ $? -eq 0 ] ; then
    echo "${PRODUCT}-${PRODUCT_VERSION} successfully added..." &>> wum.log
  else
    if [ $? -ne 1 ] ; then
      exit ${FAILED_WUM_ADD}
    fi
  fi

  # Get the updates
  echo "Get latest updates for the product - ${PRODUCT}-${PRODUCT_VERSION}..." &>> wum.log
  ${WUM} update ${PRODUCT}-${PRODUCT_VERSION} ${CHANNEL} &>> wum.log
  if [ $? -eq 0 ] ; then
    echo "${PRODUCT}-${PRODUCT_VERSION} successfully updated..." &>> wum.log
  else
    if [ $? -eq 1 ] ; then
      exit ${FAILED_WUM_UPDATE}
    fi
  fi

  # Move and unzip the WUM updated product
  echo "Moving the WUM updated product..." &>> wum.log
  ${MV} ${WUM_PRODUCT_HOME}/${PRODUCT}/${PRODUCT_VERSION}/${CHANNEL}/${PRODUCT}-${PRODUCT_VERSION}*.zip ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/${PRODUCT}-${PRODUCT_VERSION}.zip
  if [ $? -ne 0 ] ; then
    echo "Failed to move the WUM updated product from ${WUM_PRODUCT_HOME}/${PRODUCT}/${PRODUCT_VERSION}/${CHANNEL} to ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}..."
    exit ${FAILED_TO_MOVE_WUMMED_PRODUCT}
  fi
  echo "Unzip the WUM updated product..." &>> wum.log
  ${UNZIP} -q ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/${PRODUCT}-${PRODUCT_VERSION}.zip -d ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/
  if [ $? -ne 0 ] ; then
    echo "Failed to unzip the WUM updated product ${PRODUCT}-${PRODUCT_VERSION}..."
    exit ${FAILED_UNZIP}
  fi
  echo "Remove the zipped product..." &>> wum.log
  ${RM} ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/${PRODUCT}-${PRODUCT_VERSION}.zip
  if [ $? -ne 0 ] ; then
    echo "Failed to remove the zipped product ${PRODUCT}-${PRODUCT_VERSION}..."
    exit ${FAILED_RM_UNZIP}
  fi
fi

echo "Applying Puppet modules..."
puppet apply -e "include ${DEPLOYMENT_PATTERN}" --modulepath=${MODULE_PATH}
if [ $? -ne 0 ] ; then
  echo "Failed to apply Puppet for ${PRODUCT}-${PRODUCT_VERSION}..."
  exit ${FAILED_PUPPET_APPLY}
fi

echo "Applying the new artifact(s) to your WSO2 setup configuration..."
# Copy the artifact(s) to the locations(s)
${CP} -TRv ${ARTIFACT_LOCATION}/ ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/${PRODUCT}-${PRODUCT_VERSION}/
if [ $? -ne 0 ] ; then
  echo "Failed to apply the new artifact(s) to WSO2 setup ${PRODUCT}-${PRODUCT_VERSION}..."
  exit ${FAILED_ARTIFACT_APPLY}
fi

if ! $INITIAL_RUN;
then
    echo "Running the in-place updates tool..."
    ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/${PRODUCT}-${PRODUCT_VERSION}/bin/update_linux -u ${WUM_USER} -p ${WUM_PASSWORD} -c ${CHANNEL} 2>&1 | tee inplace.log
    cat inplace.log | grep "Merging configurations failed."
    if [ $? -eq 0 ] ; then
      echo "Failed to execute in-place updates for ${PRODUCT}-${PRODUCT_VERSION}. Merging configurations failed..."
      exit ${FAILED_INPLACE_UPDATES}
    fi
    echo "In-place update successfully executed for ${PRODUCT}-${PRODUCT_VERSION}..."
    ${RM} inplace.log
fi

#Create the zipped folder
echo "Creating the archive for ${PRODUCT}-${PRODUCT_VERSION}..."
cd ${WORKING_DIRECTORY}/${DEPLOYMENT_PATTERN}/
${ZIP} -q -r ${PRODUCT}-${PRODUCT_VERSION}.zip ${PRODUCT}-${PRODUCT_VERSION}/*
${MV} ${PRODUCT}-${PRODUCT_VERSION}.zip ${ZIP_OUTPUT_LOCATION}/
