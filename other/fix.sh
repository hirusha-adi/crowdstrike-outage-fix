#!/bin/bash

echo "------------"
echo "Starting the fix script..."
echo "------------"

# Create a temporary mount point
TEMP_MOUNT_POINT="/mnt/temp_mount_point"

# Save the current working directory
ORIGINAL_DIR=$(pwd)

# Create the mount point directory if it doesn't exist
mkdir -p $TEMP_MOUNT_POINT

# Get a list of all block devices
BLOCK_DEVICES=$(lsblk -ln -o NAME,TYPE | grep "disk" | awk '{print $1}')

# Loop through each block device
for DEVICE in $BLOCK_DEVICES; do
    # Get a list of all partitions for the device
    PARTITIONS=$(lsblk -ln -o NAME,TYPE | grep "part" | awk '{print $1}' | grep "^$DEVICE")

    for PARTITION in $PARTITIONS; do
        # Check if the partition is mounted
        MOUNT_POINT=$(lsblk -ln -o NAME,MOUNTPOINT | grep "^$PARTITION" | awk '{print $2}')
        echo "------------"

        if [ -z "$MOUNT_POINT" ]; then

            echo "Mounting /dev/$PARTITION."
            # Temporarily mount the partition
            sudo mount /dev/$PARTITION $TEMP_MOUNT_POINT

            if [ $? -eq 0 ]; then
                # List contents
                echo "Listing contents of $TEMP_MOUNT_POINT (for /dev/$PARTITION):"
                ls -lah $TEMP_MOUNT_POINT

                # Check for the Windows/System32/drivers/CrowdStrike/ directory
                CROWDSTRIKE_DIR="$TEMP_MOUNT_POINT/Windows/System32/drivers/CrowdStrike"

                if [ -d "$CROWDSTRIKE_DIR" ]; then
                    echo "Found CrowdStrike directory at $CROWDSTRIKE_DIR (for /dev/$PARTITION). Checking for files to delete..."

                    # Save the path to the CrowdStrike directory
                    echo "Changing directory to $CROWDSTRIKE_DIR"
                    cd "$CROWDSTRIKE_DIR"

                    # Remove files matching the pattern
                    echo "Listing files inside CrowdStrike directory before deletion"
                    ls -lah
                    echo "---"
                    echo "Deleting files matching C-00000291*.sys..."
                    rm C-00000291*.sys
                    echo "---"
                    echo "Listing files inside CrowdStrike directory after deletion"
                    ls -lah

                    # Change back to the original directory
                    cd "$ORIGINAL_DIR"

                else
                    echo "CrowdStrike directory not found at $CROWDSTRIKE_DIR (for /dev/$PARTITION)."
                fi

                # Unmount the partition
                sudo umount $TEMP_MOUNT_POINT
            else
                echo "Failed to mount /dev/$PARTITION"
            fi
        else
            echo "Partition /dev/$PARTITION is already mounted at $MOUNT_POINT"
        fi
    done
done

# Clean up: remove the temporary mount point directory
rmdir $TEMP_MOUNT_POINT

# shutdown after running the script
echo "------------"
echo "Script has finished executing, shutting down..."
echo "Made by Hirusha Adikari"
echo "------------"
sleep 4
shutdown now
