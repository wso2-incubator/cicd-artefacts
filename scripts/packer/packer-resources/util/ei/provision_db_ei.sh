#!/bin/bash
echo "Running DB scripts..."
mysql -u CF_DB_USERNAME -pCF_DB_PASSWORD -h CF_DB_HOST -P CF_DB_PORT < /home/ubuntu/ei/ei.sql
