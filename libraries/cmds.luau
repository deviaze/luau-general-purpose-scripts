local cmds = {}
local exclude_trailing_pattern = ("^([%w%s%p]+)[%s]$")
local process = require("@lune/process")
local tf = require("tf")

function cmds.ls(arg: string, get_raw: boolean?)
	local raw_results = ""
	local ops = process.os
	if ops == "windows" then
		
	elseif ops == "linux" or ops == "android" then
		local result = process.spawn(`ls`, {arg}, {shell = true})
		local stdout, stderr = result.stdout, result.stderr
		if #stdout > #stderr then
			raw_results = stdout
		else
			raw_results = stderr
		end
	end
	raw_results = raw_results:match(exclude_trailing_pattern)
	if raw_results and not get_raw then
		return raw_results:split("\n")
	elseif raw_results then
		return raw_results
	else
		return {}
	end
end

function cmds.run(cmd: string, shell: string?)
	local shell = shell or true
	local result = process.spawn(cmd, {}, {shell = shell})
	if result.ok then
		return result.stdout:match(exclude_trailing_pattern) -- remove shell trailing whitespace
	else
		return `Error with executed program: {cmd}: ` .. tf(result.stderr)
	end
end

function cmds.cls()
	if process.exec then
		if process.os == "windows" then
			process.exec("cls")
		else
			process.exec('clear')
		end
	else
		if process.os == "windows" then
			process.spawn("cls", {}, {stdio = "forward"})
		else
			process.spawn("clear", {}, {stdio = "forward"})
		end
	end
end
cmds.clear = cmds.cls

return cmds
