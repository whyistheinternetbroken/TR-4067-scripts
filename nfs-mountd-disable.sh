#!/bin/bash
##############################################################
#REPLACE THE FOLLOWING VARIABLES WITH YOUR SYSTEM'S INFO
##############################################################
# Systems
cluster_mgmt="<cluster mgmt IP or hostname>"
# SSH User names
CDOTUSR="<username with cluster admin priv>"
# Storage Virtual Machine (SVM) names; find this info with the command: vserver show -fields vserver
# Add additional SVMs as needed with VARIABLE=<SVM name>; eg. SVM3=nfs
SVM1="<SVM name>"
SVM2="<SVM name>"
# Node names; find this info with the command: node show -fields name 
# The name being used in the script will generally be the node that has the issue.
# Add additional nodes as needed with VARIABLE=<node>; eg. NODE3=node3 
NODE1="<nodename>"
NODE2="<nodename>"
###############################
#Functions - These allow more compartmentalized management of the tasks; these are repeatable with a simple function call
ConfirmDisableSysctl () {
        echo
        echo -----------------------------------------------------------
        echo
        echo You are about to disable NFS debugging with the following sysctl variables. Do you want to continue?
        echo
                echo sysvar.sktrace.AccessCacheDebug_enable: NFS Access Cache debug | sed -e 's/^/    /'
                echo sysvar.sktrace.NfsPathResolutionDebug_enable: NFS Path debug | sed -e 's/^/    /'
                echo sysvar.sktrace.NfsDebug_enable: NFS Debugging | sed -e 's/^/    /'
                echo sysvar.sktrace.MntDebug_enable: Mount Debugging | sed -e 's/^/    /'
                echo sysvar.sktrace.Nfs3ProcDebug_enable: NFSv3 Process Debugging | sed -e 's/^/    /'
                echo
        select yn in "Yes" "No"; do
            case $yn in
                Yes )   echo;
                        echo;
                        echo;
                        sleep 1;
                        break;;
                No ) ConfirmDisableMGWDDebug;;
            esac
        done
}
ConfirmDisableMGWDDebug () {
        echo
        echo
        echo You are about to disable MGWD Debug logging. Do you want to continue?
        echo
        select yn in "Yes" "No"; do
            case $yn in
                Yes )   echo;
                        echo;
                        echo;
                        sleep 1;
                        break;;
                No ) ConfirmDisableStats;;
            esac
        done
}
ConfirmDisableStats () {
        echo
        echo -----------------------------------------------------------
        echo
        echo Would you also like to disable NFS statistics for exports and mounts?
		echo
		select yn in "Yes" "No"; do
            case $yn in
                Yes )   echo;
                        echo;
                        DisableStats;
                        sleep 1;
                        break;;
                No ) break;;
            esac
        done
}
DisableStats () {
        echo
        echo -----------------------------------------------------------
        echo
        echo Review the samples below and note the sample ID.
		echo
		ssh $CDOTUSR@$cluster_mgmt "set diag -c off; statistics samples show"
		echo
		echo Enter the sample ID of the collection:
		read SAMPLE
		echo
		echo Would you like to stop statistics collection for sample ID $SAMPLE?
		echo
		select yn in "Yes" "No"; do
            case $yn in
                Yes )   echo;
                        ssh $CDOTUSR@$cluster_mgmt "set diag -c off; statistics stop -sample-id $SAMPLE"
                        sleep 1;
                        break;;
                No ) break;;
            esac
        done
}
DisableSktrace () {
ConfirmDisableSysctl
ssh $CDOTUSR@$cluster_mgmt "set diag -c off; systemshell -node $NODE1 -c "sudo sysctl sysvar.sktrace.AccessCacheDebug_enable=0""
ssh $CDOTUSR@$cluster_mgmt "set diag -c off; systemshell -node $NODE1 -c "sudo sysctl sysvar.sktrace.NfsPathResolutionDebug_enable=0""
ssh $CDOTUSR@$cluster_mgmt "set diag -c off; systemshell -node $NODE1 -c "sudo sysctl sysvar.sktrace.NfsDebug_enable=0""
ssh $CDOTUSR@$cluster_mgmt "set diag -c off; systemshell -node $NODE1 -c "sudo sysctl sysvar.sktrace.MntDebug_enable=0""
ssh $CDOTUSR@$cluster_mgmt "set diag -c off; systemshell -node $NODE1 -c "sudo sysctl sysvar.sktrace.Nfs3ProcDebug_enable=0""
echo
echo The following values were changed.
echo 
ssh $CDOTUSR@$cluster_mgmt "set diag -c off; systemshell -node $NODE1 -c "sysctl -a | grep -E 'sysvar.sktrace.AccessCacheDebug_enable|sysvar.sktrace.NfsPathResolutionDebug_enable|sysvar.sktrace.NfsDebug_enable|sysvar.sktrace.Nfs3ProcDebug_enable|sysvar.sktrace.MntDebug_enable'"" | sed -e 's/^/    /'
echo -----------------------------------------------------------
sleep 5
}
DisableMGWDdebug () {
ConfirmDisableMGWDDebug
        ssh $CDOTUSR@$cluster_mgmt "set diag -c off; logger mgwd log modify -module mgwd::exports -level err -node $NODE1"
		ssh $CDOTUSR@$cluster_mgmt "set diag -c off; logger mgwd log show -node $NODE1 -module mgwd::exports"
		echo
		echo MGWD debug logging has been disabled for exports.
		sleep 3
}
EnableSuppression () {
        ssh $CDOTUSR@$cluster_mgmt "set diag -c off; diag exports mgwd journal modify -node $NODE1 -trace-all false -suppress-repeating-errors true"
		ssh $CDOTUSR@$cluster_mgmt "set diag -c off; diag exports mgwd journal show -node $NODE1"
		echo
		echo Log suppression for exports has been re-enabled.
		sleep 3
}
#Run Functions
DisableSktrace
DisableMGWDdebug
EnableSuppression
ConfirmDisableStats
