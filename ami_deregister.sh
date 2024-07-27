#-------------------------------------------------
# Deregsiter images from AWS when:
# 1. Creation date is more than 7 days
# 2. It is not the only AMI for a given prefix
#-------------------------------------------------
epoch_ts=$(date +'%s')
deregister_packer_amis () {
  # List of name prefixes to search for
  prefixes=("RHEL8-stable" "RHEL8-unstable" "RHEL7-unstable" "RHEL7-stable")
  # Query AWS for owned images for each prefix
  for prefix in "${prefixes[@]}"; do
    # Array  to store the image IDs to deregister
    deregister_images=()
    # Query AWS for owned images for each prefix reverse sorted by CreationDate
    images=$(aws ec2 describe-images --owners self --filters "Name=name,Values=${prefix}*" --query 'reverse(sort_by(Images, &CreationDate))')
    image_count=$(echo $images | jq length)
    echo "Checking ${image_count} image(s) for ${prefix}"
    for ((count=0; count < ${image_count}; ++count)); do
      name=$(echo ${images} | jq ".[$count].Name " | sed 's/\"//g')
      image_id=$(echo ${images} | jq ".[$count].ImageId" | sed 's/\"//g')
      creation_date=$(echo ${images} | jq ".[$count].CreationDate" | sed 's/\"//g')
      # Convert the creation date to a timestamp
      image_ts=$(date -d "${creation_date}" +%s)
      delta=$((${epoch_ts} - ${image_ts}))
      # DEBUG - image details
      # echo "Got image name: ${name} ID: ${image_id} creation date: ${creation_date} and timestamp: ${image_ts}"
      if [ ${delta} -gt 604800 ]; then
        echo "Image ${image_id} is older than 7 days"
        deregister_images+=("${image_id}")
      fi
    done
    deregister_count="${#deregister_images[@]}"
    # Deregister the images if there are 2 or more images with the same prefix, leaving the newest image
    if [ ${deregister_count} -ge 2 ]; then
     for image_id in "${deregister_images[@]:1}"; do
       echo "Deregistering image ${image_id}"
       aws ec2 deregister-image --image-id ${image_id} >/dev/null 2>&1
        rc=$?
        if [ ${rc} -eq 0 ]; then
          echo "Deregistration successful"
        else
          echo "Deregistration failed: ${rc}"
        fi
     done
    fi
    unset deregister_images
  done
  echo "Deregistration script complete"
}
