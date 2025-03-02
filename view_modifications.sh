#!/bin/sh

# This is generator of bash script showing modifications to the standard versions of files
# in current directory considering that modifications are using this naming convention:
#	- modified files exist with .cor extension
#	- original files exist with .dist extension
#

echo "#!/usr/bin/bash\n"
find $1 -type f  | egrep ".cor$|.dist$" | sort | egrep -A 1 "*.cor$" | sed -z "s@[.]cor\n@.cor @g;" | sed "s@
\(.*\)@printf '%.30s%65s\\\n' \1 "================" "==================="\ndiff -y --suppress-common-lines \1
@g"
