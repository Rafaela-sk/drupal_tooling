#!/bin/bash

if [ -d web ]; then
	extra="web/"
else
	extra=""
fi

if [ -e composer.phpversion ]; then
	phpver=`cat composer.phpversion`
	printf "\nUsing enforced php version: ${phpver}\n"
else
	phpver=""
	printf "\nUsing default php version:\n`php -v`\n"
fi

dirnm=`pwd`
dirname=`basename ${dirnm}`

chmod a+w ${extra}sites/default
chmod a+w ${extra}sites/default/settings.php

php${phpver} /usr/local/bin/composer ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17} ${18} ${19} ${20} ${21} ${22} ${23} ${24} ${25} ${26} ${27} ${28} ${29} ${30} ${31} ${32} ${33} ${34} ${35} ${36} ${37} ${38} ${39} ${40} ${41} ${42} ${43} ${44} ${45} ${46} ${47} ${48} ${49} ${50}

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
