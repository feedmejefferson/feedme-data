cat */*/*/*.json|grep 'severity":"INFO'|sed 's/^.*textPayload":"//;s/","timestamp":.*$//;s~\\"~"~g;'>aggregated_logs
