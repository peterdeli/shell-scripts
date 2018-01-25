#!/bin/ksh

export NO_PROMPT=true
export MENU=false

# y=yes prompt, n=no prompt ( for removes )
# c = copy, v=verify, r=remove
# m = NO_MENU=true

while getopts yncvrm opt; do
    # echo "Option: $opt"
    case $opt in
        y) NO_PROMPT=false ;;
        n) NO_PROMPT=true ;;
        c) SE_COPY=true ;;
        v) SE_VERIFY=true ;;
        r) SE_REMOVE=true ;;
        m) MENU=true ;;
            ?) echo "Unknown option $opt"; exit ;;
    esac
done


# defaults if not set

set SE_DEBUG=${SE_DEBUG:=false}
export SE_DEBUG

set SE_COPY=${SE_COPY:=false}
export SE_COPY

set SE_RESTORE=${SE_RESTORE:=false}
export SE_RESTORE

set SE_VERIFY=${SE_VERIFY:=true}
export SE_VERIFY

set SE_REMOVE=${SE_REMOVE:=false}
export SE_REMOVE

set HOST_NUM=${HOST_NUM:=$( /bin/hostname  )}
export HOST_NUM

set ROOT_DIR=${ROOT_DIR:=SOME_DIR}
export ROOT_DIR

dest_dir=/SOME_DIR/backups/tomcat_logs/${HOST_NUM}
set DEST_DIR=${DEST_DIR:=$dest_dir}
export DEST_DIR

set DEFAULT_SUBDIRS=${DEFAULT_SUBDIRS:='tomcat_\*/logs'}
export DEFAULT_SUBDIRS

#src_dirs=$( cd $ROOT_DIR; /bin/ls -d $( eval echo $DEFAULT_SUBDIRS )  2>/dev/null )}
set SRC_DIRS=${SRC_DIRS:=$( cd $ROOT_DIR; /bin/ls -d $( eval echo $DEFAULT_SUBDIRS )  2>/dev/null )}
export SRC_DIRS

NO_FILES=false

# default verify
choice=2
response=""


menu(){
cat <<EOF

******************************
******************************

1. Copy 
2. Verify 
3. Remove
4. Copy & Verify
5. Verify & Remove
6. Copy & Verify & Remove
7. Restore

******************************
******************************

EOF
echo -n "Choice: "
read response
set_flags

}

restore(){

    echo "Restoring files from to $DEST_DIR/$1 $ROOT_DIR/$1" 
    cd $DEST_DIR
    SRC_DIR=$1
    eval $debug_prompt
    echo $1 
    for file in ${SRC_DIR}/*.gz; do
        if [ ! -f ${ROOT_DIR}/$file ]; then
            echo "tar cf - $file | ( cd $ROOT_DIR;  tar xkvf - )"
            tar cf - $file | ( cd $ROOT_DIR;  tar xkvf - )
            if [ $? -ne 0 -o ! -f $file ]; then
                echo "Error copying $file to $ROOT_DIR. Press return to continue, Ctrl-C to quit"
                eval $debug_prompt
            fi
        else
            echo "File $file exists: in ${ROOT_DIR}/$file"
        fi

    done
    echo "Done"
}

copy(){

    NO_FILES=false
    # check for files
    # check for gzips
    gzips=$( find $1 -name \*.gz -maxdepth 1 2>/dev/null | wc -l )
    if [ $gzips -gt 0 ]; then
    echo "Moving files in ${ROOT_DIR}/$1"
    echo "Folder: ${ROOT_DIR}/${1}"
    echo "Command: tar cf - ${1}/*.gz | ( cd $DEST_DIR;  tar xvf - )" 
    eval $debug_prompt
    echo "${ROOT_DIR}/${1}"
    tar cf - ${1}/*.gz | ( cd $DEST_DIR;  tar xvf - ) 
    if [ $? -ne 0 ]; then
        exit
    fi
     else
     echo "No files found in ${ROOT_DIR}/$1"
     NO_FILES=true
     fi
    echo "Done"

}
remove(){
   return=1
   if [ $NO_FILES = "true" ]; then
    return $return
   fi
    if [ $NO_PROMPT = "y" ]; then
        echo "Press 'y' to remove files in $1"
        read do_remove
    else
        do_remove=y
    fi
    if [ $do_remove = "y" ]; then
        if [ -d $1 ]; then
            cur=$PWD
            cd $1
            echo "Removing .gz files in $PWD" 
        
            for gz in ${PWD}/*.gz; do
          if [ -f $gz ]; then 
              echo $gz
              rm -f $gz
          fi
            done 
            echo
            cd $cur
        fi
        echo "Done"
    else
        echo "Cancelling remove"
    fi

}
verify(){
   return=1
   if [ $NO_FILES = "true" ]; then
    return $return
   fi
   echo "Verifying files in $1"
   if [ -d $1 ]; then
        for j in $( find $1 -maxdepth 1 -name \*.gz ); do
            if [ ! -f $j  ]; then
                echo
                echo "WARNING: Source file(s) $j not found!"
        return=-1
                eval $debug_prompt
            elif [ ! -f ${DEST_DIR}/$j ]; then
                echo
                echo "WARNING: Destination file ${DEST_DIR}/$j not found!"
                eval $debug_prompt
        return=-1
            fi
                echo -n "."
                src=$( cksum $j | cut -d' ' -f1 )
                dest=$( cksum ${DEST_DIR}/$j | cut -d' ' -f1 )
            if [ "XX$src" != "XX$dest" ]; then
                echo
                echo "WARNING: Source file $PWD/$j doesn't match Destination: [ $src ] != [ $dest ]"
                eval $debug_prompt
        return=-1
            fi
        done
        echo 
        echo "Done"
    else
        echo "ERROR: Directory $1 not found"
    return=-1
    fi
    if [ $return -eq -1 ]; then
    exit $return
    fi 
}

set_flags(){
    case $response in
        1) echo "Copy"; 
            export SE_COPY=true
            export SE_VERIFY=false
            export SE_REMOVE=false
            export SE_RESTORE=false
        ;;
        2) echo "Verify"; 
            export SE_VERIFY=true
            export SE_COPY=false
            export SE_REMOVE=false
            export SE_RESTORE=false
        ;;
        3) echo "Remove"; 
            export SE_REMOVE=true
            export SE_VERIFY=false
            export SE_COPY=false
            export SE_RESTORE=false
        ;;
        4) echo "Copy & Verify"; 
            export SE_COPY=true; 
            export SE_VERIFY=true;
            export SE_REMOVE=false
            export SE_RESTORE=false
        ;;
        5) echo "Verify & Remove"
            export SE_COPY=false
            export SE_VERIFY=true
            export SE_REMOVE=true
            export SE_RESTORE=false
        ;;
        6) echo "Copy & Verify & Remove"
            export SE_COPY=true
            export SE_VERIFY=true
            export SE_REMOVE=true
            export SE_RESTORE=false
        ;;
        7) echo "Restore"
            export SE_COPY=false
            export SE_VERIFY=false
            export SE_REMOVE=false
            export SE_RESTORE=true
        ;;
        *) echo "Incorrect Response"; menu ;;
    esac
    choice=$response

}


debug_prompt=""
if [ $SE_DEBUG = true ]; then
    debug_prompt="read this"
fi


if [ $# -eq 0 ]; then
    export MENU=true
fi


if [ $MENU = true ]; then 
	    menu
fi

cd $ROOT_DIR

if [ "XX$SRC_DIRS" != "XX"  ]; then

  
    if [ ! -d $DEST_DIR ]; then
        echo "$DEST_DIR not found, attempting to create .."
        mkdir -p $DEST_DIR
        err=$?
        if [ $err -ne 0 ]; then
          echo "Create of $DEST_DIR failed, exiting .."
          exit $err
        fi
    fi
        
    for i in $SRC_DIRS; do 
        if [ ! -z "$SE_COPY" -a $SE_COPY = true ]; then
            copy $i
        fi
        if [ ! -z "$SE_VERIFY" -a $SE_VERIFY = true ]; then
            verify $i
        fi
        if [ ! -z "$SE_REMOVE" -a $SE_REMOVE = true ]; then
            remove $i
        fi
        if [ ! -z "$SE_RESTORE" -a $SE_RESTORE = true ]; then
            restore $i
        fi
    done
else
    echo "No source directories to move"
fi
