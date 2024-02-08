#!/bin/bash
# Uncomment for debug
#set -x

. duplicity.conf

# Modify the usage text to reflect the changes
USAGE=$(cat <<-EOF
    Usage: $(basename "$0") [OPTIONS] COMMAND [ARGUMENT]

    Options:
      -h, --help     Show this help message and exit

    Commands:
      full           Perform a full backup
      incr           Perform an incremental backup
      remove-older   Remove older backups
      restore        Restore data from backup (RPATH, LPATH)
      full-restore   Perform a full restore
      verify         Verify the integrity of the backup
      delete-logs    Delete all logs

    Examples:
      $(basename "$0") full
      $(basename "$0") restore /path/to/source /path/to/restore
      $(basename "$0") full-restore
EOF
)

function do_full_backup {
    for dir in "${DIRECTORIES[@]}"; do
        if [ "$dir" != "/" ]; then
            dirname="${dir:1}"
	    EXCLUDES=
        else
            dirname="root"
        fi

        dest="$REMOTE/$dirname"

        duplicity full --encrypt-key $ENCRKEY \
            --sign-key $SIGNKEY \
            --log-file "logs/duplicity-full_$(date +%d-%m-%Y).log" \
            $EXCLUDES \
            $dir $dest
    done
}

function do_incr_backup {
    for dir in "${DIRECTORIES[@]}"; do
        if [ "$dir" != "/" ]; then
            dirname="${dir:1}"
	    EXCLUDES=
        else
            dirname="root"
        fi

        dest="$REMOTE/$dirname"

        duplicity incr --encrypt-key $ENCRKEY \
            --sign-key $SIGNKEY \
            --log-file "logs/duplicity-incr_$(date +%d-%m-%Y).log" \
            $EXCLUDES \
            $dir $dest

    done   
}

function remove_older {
    for dir in "${DIRECTORIES[@]}"; do
        if [ "$dir" != "/" ]; then
            dirname="${dir:1}"
	    EXCLUDES=
        else
            dirname="root"
        fi

        dest="$REMOTE/$dirname"

        duplicity remove-older-than 1M --encrypt-key $ENCRKEY \
            --sign-key $SIGNKEY \
            --log-file "logs/duplicity-remvold_$(date +%d-%m-%Y).log" \
            $dest
    done
}

# Requires two additional arguments: source path and destination path to restore.
function restore {
    if [ "$#" -ne 2 ]; then
        echo "Error: Missing or incorrect number of arguments for restore command"
        print_usage
        exit 1
    fi

    source_folder="$1"
    dest_folder="$2"

    duplicity restore --encrypt-key $ENCRKEY \
        --sign-key $SIGNKEY \
        --log-file "logs/duplicity-restore_$(date +%d-%m-%Y).log" \
        --force \
        $source_folder $dest_folder
}

# Full restore does not require any additional arguments.
function do_full_restore {
    for dir in "${DIRECTORIES[@]}"; do
        if [ "$dir" != "/" ]; then
            dirname="${dir:1}"
	    EXCLUDES=
        else
            dirname="root"
        fi

        src="$REMOTE/$dirname"
        restore "$src" "$dir"
    done
}

# TODO: Needs to be adapted.
function do_verify {
    duplicity verify --log-file "logs/duplicity-verify_$(date +%d-%m-%Y).log" $EXCLUDES $REMOTE /
}

function delete_logs {
    rm -f logs/*
}

function print_usage {
    echo "$USAGE"
}

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        full|incr|remove-older|restore|full-restore|verify|delete-logs)
            COMMAND="$1"
            shift
            ;;
        *)
            if [ "$COMMAND" == "restore" ]; then
                restore "$1" "$2"
                exit 0
            elif [ "$COMMAND" == "full-restore" ]; then
                do_full_restore
                exit 0
            else
                echo "Error: Unknown option or missing argument"
                print_usage
                exit 1
            fi
            ;;
    esac
done

# Execute the specified command
case "$COMMAND" in
    full)
        do_full_backup
        ;;
    incr)
        do_incr_backup
        ;;
    remove-older)
        remove_older
        ;;
    restore)
        echo "Error: Missing argument for restore command"
        print_usage
        exit 1
        ;;
    full-restore)
        do_full_restore
        ;;
    verify)
        do_verify
        ;;
    delete-logs)
        delete_logs
        ;;
    *)
        echo "Error: Unknown command $COMMAND"
        print_usage
        exit 1
        ;;
esac
