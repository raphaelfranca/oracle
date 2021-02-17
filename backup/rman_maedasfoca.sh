#!/bin/bash
##############################################################################
#                            RMAN BACKUPS MAEDASFOCA   	                     #
##############################################################################
#									     #
# Description: This script create a RMAN backup based on parameter passed    #
#									     #
##############################################################################
#									     #
# Author: Raphael França <raphael.franca@inteller.com.br>                    #
# Version : 1.0 (2021-02-17)						     #
#									     #
##############################################################################

BACKUP_TYPE=$1 #CDB, PDB
BACKUP_LEVEL=$2 #FULL, INCR, DIFF
BACKUP_PDBS=$3

usage () {
echo "
##############################################################################
#                            RMAN BACKUPS MAEDASFOCA			     #
##############################################################################
#									     #
# Description: This script create a RMAN backup based on parameter passed    #
#									     #
##############################################################################
#									     #
# Author: Raphael França <raphael.franca@inteller.com.br>                    #
# Version : 1.0 (2021-02-17)						     #
# BACKUP_TYPE: CDB, PDB							     #
# BACKUP_LEVEL: FULL, INCR, DIFF					     #
# BACKUP_PDBS: PDB NAMES SEPARATED BY COMMA				     #
#									     #
# example cdb backup full : rman_maedasfoca.sh CDB FULL X		     #
# exemple pdb backup full : rman_maedasfoca.sh PDB FULL PDB1, PDB2	     #
##############################################################################
"
}

# Validating du number of parameters passed
if [ $# -lt 3 ]; then
    usage
    exit 1
fi

# Backup type validation
case $BACKUP_LEVEL in
    FULL)
        LEVEL="LEVEL = 0"
    ;;
    INCR)
        LEVEL="LEVEL = 1"
    ;;
    DIFF)
        LEVEL="LEVEL = 1 CUMULATIVE"
    ;;    
    *)
        usage
    exit 1
    ;;
esac
#load so user env oracle params 
. /home/oracle/.bash_profile

function backup_cdb() {
	RUN="
		RUN {    
			BACKUP
			 INCREMENTAL ${LEVEL}
			 FILESPERSET = 32
			 (ARCHIVELOG ALL)
			 DATABASE INCLUDE CURRENT CONTROLFILE;
			 DELETE NOPROMPT OBSOLETE;
			 DELETE NOPROMPT EXPIRED BACKUP;
			 CROSSCHECK ARCHIVELOG ALL;
		}
	"
	echo "$RUN"
}

function backup_pdb() {
	RUN="
		RUN {    
			BACKUP
			 INCREMENTAL ${LEVEL}
			 FILESPERSET = 32
			 (ARCHIVELOG ALL)
			 PLUGGABLE DATABASE ${BACKUP_PDBS};	 
		}
	"
	echo "$RUN"
}

#execute rman

if [ $BACKUP_TYPE = 'CDB' ]; then
	backup_cdb
	${ORACLE_HOME}/bin/rman << EOF 

	connect target /      
	
	${RUN}
EOF

else
	backup_pdb
	${ORACLE_HOME}/bin/rman << EOF

	connect target /      
	
	${RUN}

EOF

fi