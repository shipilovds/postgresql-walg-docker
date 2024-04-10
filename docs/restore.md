# Restore from backup

Restoring data from a wal-g backup can be achieved through two possible methods:

- Automated
- Manual

To comprehend the automated process, let's first delve into the manual approach. However, before diving into either method, there's a common preparatory phase:

## Preparations

1. Stop docker contaners.
2. Set `MAINTENANCE=true` and `WALG_ENABLED=false` in environment
3. Start contaners
   > `wal-g-worker` container isn't needed at this step and can be skipped.

#### Additional (but important!) point

To restore data, we need to pinpoint the time in its history we wish to rewind to. There are only two options:

- Full Recovery - Restoration to the latest moment
- Point In Time Recovery (PITR) - Choosing an exact moment in time to restore to

## Main action

I've hidden the details of the *Manual Restoration* process [here](restore_manual.md) to enhance readability on this page. You can skip this part if you prefer the automated method.

### Automated (almost) recovery

Simply execute `/var/lib/wal-g-utils/recovery.sh` in the container and follow the wizard and post-instructions. You're welcome =)
