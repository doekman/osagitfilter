#@osa-lang:AppleScript Debugger
use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use framework "OSAKit"
use scripting additions

«event asDBDBid» "CF0107E8-55C4-42E0-80BF-2C20409AF636"
tell me to «event asDBLine» {1, 0, {}}
set availableLanguages to current application's OSALanguage's availableLanguages()
tell me to «event asDBLine» {2, 0, {}}
set langList to {}
tell me to «event asDBLine» {3, 0, {}}
repeat with lang in availableLanguages
	tell me to «event asDBLine» {4, 0, {"lang", {lang, 0} as «class bst»}}
	set end of langList to lang's |name|() as text
end repeat
tell me to «event asDBLine» {5, 0, {}}
langList
