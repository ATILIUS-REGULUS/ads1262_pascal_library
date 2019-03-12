# #! /bin/bash -e

cd /home/pi/pascal/ads1262_library/master/

echo "#################"
echo "#### Compile ####"
echo "#################"
if /usr/local/codetyphon/typhon/bin32/typhonbuild ./ads1262_project.ctpr; then
  echo
  echo "#######################"
  echo "#### Start program ####"
  echo "#######################"
  ./ads1262_project
fi

read key
