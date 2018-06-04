## Sensu Checks/Metrics for Windows using CIM 
Due to the poor performance at scale of the windows checks and metrics included in the sensu community repo, I've written ones that run in about a quarter of the time, without the large CPU hit.

All metrics live in a single script to stop spawning as many powershell instances.  The output is Influx line protocol.

This has only been tested on server 2008/2012 R2 with powershell-core (powershell 6)