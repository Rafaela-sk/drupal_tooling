#!/bin/bash

if [ -d web ]; then
	extra="web/"
else
	extra=""
fi

dirnm=`pwd`
dirname=`basename ${dirnm}`

chmod a+w ${extra}sites/default
chmod a+w ${extra}sites/default/settings.php

php /usr/local/bin/composer $1 $2 $3 $4 $5 $6 $7 $8 $9

chmod a-w ${extra}sites/default
chmod a-w ${extra}sites/default/settings.php

./vendor/drush/drush/drush -y updatedb
./vendor/drush/drush/drush cache:rebuild

echo ""
echo ""
echo "######################################################################"
echo "Next possible steps:"
echo "./vendor/drush/drush/drush -y updatedb"
echo "./vendor/drush/drush/drush cache:rebuild"
echo ""
echo "### MODULE INSTALL ###"
echo "./vendor/drush/drush/drush pm:install [module_name]"
echo ""
echo "### BACKUP ###"
echo "./vendor/drush/drush/drush archive:dump --exclude-code-paths=sites/default/settings.php --destination=~/${dirname}_drush_`date +'%Y%m%d'`.tar.gz"
echo "cp sites/default/settings.php ~/${dirname}_drush_`date +'%Y%m%d'`.settings.php"
echo ""
echo "### RESTORE ###"
echo "./vendor/drush/drush/drush archive:restore ${dirname}_drush_`date +'%Y%m%d'`.tar.gz --destination-path=${dirnm}"
echo "######################################################################"
echo ""
echo ""
