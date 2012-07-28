#!/bin/bash

# get the current working project directory
SOURCE="${BASH_SOURCE[0]}";
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
project="$( cd -P "$( dirname "$SOURCE" )" && pwd )";
project=$(dirname "$project");

asdoc="$project/sdk/flex/bin/asdoc"
docs="$project/src/"
output="$project/docs/"
flash="/Applications/Adobe Flash CS4/Common/Configuration/ActionScript 3.0"

rm -rf "project/docs/*"

$asdoc \
-source-path $docs \
-doc-sources $docs \
-output $output \
-main-title "AnimationController ActionScript 3.0 API Reference" \
-window-title "AnimationController ActionScript 3.0 API Reference" \
-left-frameset-width 220 \
-package com.psyrendust.control "The com.psyrendust.control package contains controller classes for SWF's and movie clips." \
-package com.psyrendust.control.events "The com.psyrendust.control.events package contains event classes specific to the com.psyrendust.control package." \
-package com.psyrendust.control.types "The com.psyrendust.control.types package contains type classes specific to the com.psyrendust.control package." \
-package com.psyrendust.managers "The com.psyrendust.managers package contains manager classes that simplify many mundane programming tasks." \
-package com.psyrendust.managers.types "The com.psyrendust.managers.types package contains type classes specific to the com.psyrendust.managers package."