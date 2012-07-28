#!/bin/bash

# get the current working project directory
SOURCE="${BASH_SOURCE[0]}";
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
project="$( cd -P "$( dirname "$SOURCE" )" && pwd )";
project=$(dirname "$project");

compc="$project/sdk/flex/bin/compc";
classes="$project/src/";
output="$project/bin/AS3AnimationController.swc";

$compc \
-source-path $classes \
-include-classes \
com.psyrendust.control.AnimationController \
com.psyrendust.control.events.AnimationControllerEvent \
com.psyrendust.control.events.AnimationControllerListenerEvent \
com.psyrendust.control.types.AnimationControllerType \
com.psyrendust.managers.CallbackManager \
com.psyrendust.managers.types.CallbackManagerType \
-output=$output