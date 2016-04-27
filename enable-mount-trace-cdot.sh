#!/bin/bash
# Linux/UNIX box with ssh key based login enabled
# Systems; find the IP address with the command "net int show -role cluster-mgmt -fields address"
cluster_mgmt="<IP Address of cluster management LIF>"
# SSH User names
CDOTUSR="<cDOT login name with cluster admin privileges>"
# Storage Virtal Machine/vserver (SVM) Names; add additional SVMs as needed - find SVMs with "vserver show"
SVM1="<SVM name 1>"
SVM2="<SVM name 2>"
# Node names; add additional node names as needed. Find the node name with "node show -fields node" command. Node name will depend on where the errors are taking place.
NODE1="<node name 1>"
NODE2="<node name 2>"
# This script enables debug logging for NFS mount tracing in NetApp clustered Data ONTAP. Variables are specified above.
#Functions
# The specified node name should be the node that is experiencing the issue. Multiple nodes can be specified with comma separated values ($NODE1,$NODE2)
EnableSktrace () {
        ssh $CDOTUSR@$cluster_mgmt set diag -c off; systemshell -node $NODE1 -c "sudo sysctl sysvar.sktrace.AccessCacheDebug_enable=-1;sudo sysctl sysvar.sktrace.NfsPathResolutionDebug_enable=63;sudo sysctl sysvar.sktrace.NfsDebug_enable=63;sudo sysctl sysvar.sktrace.MntDebug_enable=-1;sudo sysctl sysvar.sktrace.Nfs3ProcDebug_enable=63;sudo sysctl sysvar.sktrace.NfsDebug_enable=-1"
}
# The specified node name should be the node that is experiencing the issue. Multiple nodes can be specified with comma separated values ($NODE1,$NODE2)
EnableMGWDdebug () {
        ssh $CDOTUSR@$cluster_mgmt set diag -c off; logger mgwd log modify -module mgwd::exports -level debug -node $NODE1
}
# The specified node name should be the node that is experiencing the issue. Multiple nodes can be specified with comma separated values ($NODE1,$NODE2)
DisableSuppression () {
        ssh $CDOTUSR@$cluster_mgmt set diag -c off; diag exports mgwd journal modify -node $NODE1 -trace-all true -suppress-repeating-errors false
}
#Run Functions
EnableSktrace
EnableMGWDdebug
DisableSuppression
