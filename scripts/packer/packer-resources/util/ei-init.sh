#!/usr/bin/env bash
# ----------------------------------------------------------------------------
#
# Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# ----------------------------------------------------------------------------

exec &> /home/ubuntu/logfile.txt
readonly WUM_USERNAME=$1
readonly WUM_PASSWORD=$2

PACK_DIRECTORY=/etc/puppet/code/environments/production/modules/installers/files
WSO2_SERVER_PACK=wso2ei-6.4.0.zip
WSO2_SERVER_UPDATED_PACK=wso2ei-6.4.0*.zip
WUM_PRODUCT_LOCATION=/home/ubuntu/.wum3/products/wso2ei/6.4.0/full
WUM_LOCATION=/usr/local/wum/bin/wum

sudo -u ubuntu ${WUM_LOCATION} init -u ${WUM_USERNAME} -p ${WUM_PASSWORD} -v

sudo -u ubuntu ${WUM_LOCATION} add --file ${PACK_DIRECTORY}/${WSO2_SERVER_PACK} -y

#sed -i "s/WUNMR2hnaGdIU25FajB4SngzNkRSeDFOT1pVYTp5enB4SWd6bWpncjVlWWNkdXFhblpYc2JCRXNh/R0dnZThYMmk2T2E2ZldjbHhKWWplTV93REJFYTo5Q0FGbG1oR09ZbjRhTzkyNFp5REh6VEZFeTBh/g" /home/ubuntu/.wum3/config.yaml
#sed -i '0,/https:\/\/api.updates.wso2.com/{s/https:\/\/api.updates.wso2.com/https:\/\/gateway.api.cloud.wso2.com\/t\/wso2umuat/}' /home/ubuntu/.wum3/config.yaml
#
#sudo -u ubuntu ${WUM_LOCATION} init -u ${WUM_USERNAME} -p ${WUM_PASSWORD} -v

sudo -u ubuntu ${WUM_LOCATION} update wso2ei-6.4.0

#sudo rm /etc/update-motd.d/00-header
#sudo rm /etc/update-motd.d/10-help-text
#sudo rm /etc/update-motd.d/50-landscape-sysinfo

if [ ! -f ${WUM_PRODUCT_LOCATION}/${WSO2_SERVER_UPDATED_PACK} ];then
  sudo mv /home/ubuntu/MOTD-Without/51-cloudguest /etc/update-motd.d/51-cloudguest
  sudo chmod +x /etc/update-motd.d/51-cloudguest
else
  sudo mv /home/ubuntu/MOTD-With/51-cloudguest /etc/update-motd.d/51-cloudguest
  sudo chmod +x /etc/update-motd.d/51-cloudguest
  sudo mv ${WUM_PRODUCT_LOCATION}/${WSO2_SERVER_UPDATED_PACK} /etc/puppet/code/environments/production/modules/installers/files/${WSO2_SERVER_PACK}
fi
