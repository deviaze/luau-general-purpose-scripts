
local fs = require("@lune/fs")
local process = require("@lune/process")
local net = require("@lune/net")
local datetime = require("@lune/datetime")

local Lists = require("libraries/Lists")
local List, PairedList = Lists.List, Lists.PairedList

type List<T> = Lists.List<T>
type PairedList<K,V> = Lists.PairedList<K,V>

local strip_comments_from_jsonc_pattern = "%s//[%w%p ]*\n"
local raw_config = fs.readFile(".config-android.jsonc"):gsub(strip_comments_from_jsonc_pattern, "")

export type CanvasGetterConfig = {
      CANVAS_API_KEY: string,
      BASE_URL: string,
      Classes: {
            [string]: {
                  classid: string,
                  output_dir: string,
                  query: "Files" | "Modules",
            }
      }
}
type FileProperties = {
      display_name: string,
      file_name: string,
      id: number,
      updated_at: string,
      url: string,
      [string]: any,
}
type FilteredFile = {
	display_name: string,
	url: string,
	updated_at: string,
	
}

local config = net.jsonDecode(raw_config) :: CanvasGetterConfig
local API_KEY = config.CANVAS_API_KEY
local BASE_URL = config.BASE_URL .. "/courses"

local args = table.concat(process.args, ",")
local filter_days = args:match("(%d+),") or 7
local search_term = args:match(",([%w%s%p]+)$")

local seconds_per_day = 60 * 60 * 24
local today_unix = datetime.now().unixTimestamp

for class, info in config.Classes do
	local output_dir = info.output_dir
	if not fs.isDir(output_dir) then
		print(`Invalid class directory:\n  {class}: {output_dir}`)
		continue
	end
	
	-- process.exit()
	local url = `{BASE_URL}/{info.classid}/{info.query:lower()}?`
	local response = net.request {
		url = url,
		query = {
			sort = "updated_at",
			order = "desc",
			access_token = API_KEY,
		}
	}
	
	local fields = List.new("display_name", "url", "updated_at")
	type WantedFields = {url: string, file_name: string, updated_at: number}
	if response.ok then
		local files = List.from(net.jsonDecode(response.body)):map(function(file: FileProperties)
			return PairedList.remap_dictionary(file, function(property: string, value: any)
				if fields:has(property) then
					if property == "updated_at" then
						value = datetime.fromIsoDate(value).unixTimestamp
					end
					return {[property] = value}
				end
				return nil
			end)
		end)
		
		local filtered_files = files:map(function(file: FileProperties)
			if (today_unix - file.updated_at)/seconds_per_day < filter_days then
				return file
			else
				return nil
			end
		end)
		
		print(`{class}:`)
		local directory_files = List.from(fs.readDir(output_dir))
		filtered_files:each(function(file: FilteredFile)
			if not directory_files:has(file.display_name) then
				local result = process.spawn("curl", {"-L", `-o{file.filename}`, file.download_link}, {
					cwd = output_dir
				})
				print(result.stderr)
				print(result.stdout)
				process.exit()
				if result.stderr:match("100") then
					print(` +  successfully downloaded {output_dir}/{file.display_name}`)
				else
					print(` !! error downloading {file.display_name} to {output_dir}`)
				end
			else
				print(` - already downloaded: {file.display_name}`)
			end
		end)
	end
end
