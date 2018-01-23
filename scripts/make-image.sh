#/bin/sh

VERSION=0.21
IMAGE_NAME=xAudic-${VERSION}
IMAGE_FILE=/tmp/${IMAGE_NAME}_tmp.dmg
DIMAGE_FILE=/tmp/${IMAGE_NAME}.dmg

check_result()
{
    if [ $2 != 0 ]; then 
      echo "Error running: $1"
      exit 1
    fi
}

if [ -f $IMAGE_FILE ]; then
    echo "Removing old image file: $IMAGE_FILE"
    sudo rm $IMAGE_FILE
fi

if [ -f $DIMAGE_FILE ]; then
    echo "Removing old image file: $DIMAGE_FILE"
    sudo rm $DIMAGE_FILE
fi

STEP="Creating Image..."
echo $STEP
hdiutil create -megabytes 10 $IMAGE_FILE -layout NONE -zeroImage
check_result "$STEP" $?

STEP="Mounting Image..."
echo $STEP
DEVICE=`hdid -nomount $IMAGE_FILE`
check_result "$STEP" $?

STEP="Creating file system..."
echo $STEP
sudo /sbin/newfs_hfs -v $IMAGE_NAME $DEVICE
check_result "$STEP" $?

STEP="Ejecting device..."
echo $STEP
hdiutil eject $DEVICE
check_result "$STEP" $?

STEP="Re-Mounting Image"
echo $STEP
DEVICE=`hdid $IMAGE_FILE`
check_result "$STEP" $?
DEVICE=`echo $DEVICE | awk -F' ' '{print $1;}'`

VOLUME="/Volumes/$IMAGE_NAME"
while [ ! -d "$VOLUME" ]; do
  echo "Waiting for mount..."
  sleep 5
done

#STEP="Copying files..."
STEP="Installing Application..."
echo $STEP
pbxbuild -buildstyle Deployment install DSTROOT=/ INSTALL_PATH=$VOLUME
check_result "$STEP" $?

STEP="Eject Device..."
echo $STEP
hdiutil eject $DEVICE
check_result "$STEP" $?

STEP="Converting to UDCO.."
echo $STEP
sudo hdiutil convert -format UDCO $IMAGE_FILE -o $DIMAGE_FILE -noext
check_result "$STEP" $?

echo "Done. Final image is $DIMAGE_FILE"



