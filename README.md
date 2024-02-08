# Duplicity wrapper script

A wrapper script for duplicity.

## Usage

You need to complete the config file `duplicity.conf`.

```
user@machine:~$ ./dup-wrap.sh -h
    Usage: dup-wrap.sh [OPTIONS] COMMAND [ARGUMENT]

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
      dup-wrap.sh full
      dup-wrap.sh restore /path/to/source /path/to/restore
      dup-wrap.sh full-restore
```

## Known issues

- The option `verify` does not work correctly, needs to be adapted.
- Functions can be simplified by extracting the loop code.

