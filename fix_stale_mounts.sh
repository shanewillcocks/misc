#!/usr/bin/bash
#------------------------------------------
# Find and remove autofs mounts that
# have not unmounted automatically
#------------------------------------------
trap 'rm -vf /tmp/nfs_mounts*' EXIT

script=$(basename $0 | awk -F'.' '{print $1}')
tmpfile1=/tmp/nfs_mounts.1
tmpfile2=/tmp/nfs_mounts.2
logfile=/tmp/${script}.log
nfs_count=0
umt_count=0

log_this () {
    echo ${1}
    echo $(date '+%d/%m/%Y %T') - ${1} >> ${logfile}
}

# Find all nfs4 mounts
get_mounts () {
    mount | grep autofs | grep '/home/[lpuz]+*[0-9]' | grep -v grep | awk '{print $3}' > ${tmpfile1}
    perl -p -i -e 's/\/net\/u[xt]+store\/export//g' ${tmpfile1}
    sort --unique ${tmpfile1} > ${tmpfile2}
    nfs_count=$(cat ${tmpfile2} | wc -l)
    log_this "Found ${nfs_count} nfs mounts, checking for stale mounts:"
}

# For all mounts found check if active, if not unmount
fix_mounts () {
    while read line
    do
    lsof ${line} > /dev/null 2>&1
    rc=$?
    if [[ ${rc} -eq 0 ]]; then
        log_this "Ignoring ${line} - mount in use"
    elif [[ ${rc} -gt 0 ]]; then
        log_this "Unmounting ${line} - mount is unused"
        #umount -f ${line}
        umt_count=$((umt_count+1))
    fi
    done < ${tmpfile2}
    log_this "Unmounted ${umt_count} unused nfs mounts"
}
get_mounts
fix_mounts
exit
