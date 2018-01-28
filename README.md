osagitfilter
============

Filter to put [OSA][] languages (AppleScript, JavaScript) into a `git`-repository. 

Default, it prevents from accidently checkin in AppleScript files with Debugging Mode (from [AppleScript Debugger][asdbg]) switched on.

Based on [this answer by Daniel Trebbien][so-ascr-in-git] on stackoverflow and help from [guys on the Script Debugger Forum][asdbg-forum].



Installation
------------

Either clone [this repository](https://github.com/doekman/osagitfilter), or download the [latest release](https://github.com/doekman/osagitfilter/releases).

Configure the filter by running the following command:

	./setup.sh configure


Make the filter available to git by running [git config][gitconfig] (with or without the `--global` argument):

	git config --global filter.osa.clean "osagitfilter --clean"
	git config --global filter.osa.smudge "osagitfilter --smudge"
	git config --global filter.osa.required "true"


Put the line `*.scpt filter=osa` in your [gitattributes][] of your repository, for example by running the following command from within your repository directory:

	echo "*.scpt filter=osa" >> .gitattributes

If you want to debug the script, use the following git config instead:

	git config --global filter.osa.clean "osagitfilter --clean --log %f" 
	git config --global filter.osa.smudge "osagitfilter --smudge --log %f" 
	git config --global filter.osa.required "true"


[OSA]: https://developer.apple.com/library/content/documentation/AppleScript/Conceptual/AppleScriptX/Concepts/osa.html "Apple's Open Scripting Architecture"
[asdbg]: http://latenightsw.com
[so-ascr-in-git]: https://stackoverflow.com/a/14425009/56
[asdbg-forum]: http://forum.latenightsw.com/t/cross-play-between-script-debugger-and-script-editor/834/5
[gitconfig]: https://git-scm.com/docs/git-config
[gitattributes]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes


