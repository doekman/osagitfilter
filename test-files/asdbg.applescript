on run (arg)
	«event asDBCall» {"run", "74DFFE06-66CC-46FA-8069-458659857914"} returning __asDB
	«event asDBDBid» "74DFFE06-66CC-46FA-8069-458659857914"
	tell me to «event asDBEcho» {__asDB, {"arg", {arg, 0} as «class bst»}} given x:{"arg"}
	tell me to «event asDBLine» {1, __asDB, {}}
	log "foutje"
	tell me to «event asDBRetn» __asDB
end run

