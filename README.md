osagitfilter
============

Filter to put [OSA][] languages into a `git`-repository. So you can put your `.scpt`-file (AppleScript, JavaScript) into your git-repository, and get full textual diff support.


Installation
------------

Either clone [this repository](https://github.com/doekman/osagitfilter), or download the [latest release](https://github.com/doekman/osagitfilter/releases/latest) and unzip it to a folder where you want to install it.

Configure the filter by running the following command:

	./setup.sh configure

For every reporistory you want to use it, put the line `*.scpt filter=osa` in the [gitattributes][] of your repository. Do this by running the command below in the root of your repository:

	echo "*.scpt filter=osa" >> .gitattributes


Extra's
-------

If you want to add your own git configuration, use the following configure command:

	./setup.sh configure --no-git

To reset the configuration, run this command:

	./setup.sh reset

If you have trouble with the script, switch on logging with:

	./setup.sh configure --git-log

Logging can be found in `~/Library/Logs/Catsdeep/osagitfilter.log` and can be easy inspected with `Console.app`.

Some git-clients, like GitHub Desktop, can be quite chatty so log files grow quite fast. With the following command you can create a new log file, while preserving the old ones:

	./setup.sh rotate

Default, it prevents from accidently committing AppleScript files with Debugging Mode (from [AppleScript Debugger][asdbg]) switched on. Run `osagitfilter --help` to see more options.


Credits
-------

Based on [this answer by Daniel Trebbien][so-ascr-in-git] on stackoverflow and help from [guys on the Script Debugger Forum][asdbg-forum].



[OSA]: https://developer.apple.com/library/content/documentation/AppleScript/Conceptual/AppleScriptX/Concepts/osa.html "Apple's Open Scripting Architecture"
[asdbg]: http://latenightsw.com
[so-ascr-in-git]: https://stackoverflow.com/a/14425009/56
[asdbg-forum]: http://forum.latenightsw.com/t/cross-play-between-script-debugger-and-script-editor/834/5
[gitconfig]: https://git-scm.com/docs/git-config
[gitattributes]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Attributes
