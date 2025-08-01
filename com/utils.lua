-- utils.lua by jakubg1
-- version for all the new stuff! (I need to find a more exhaustively edited one)

---It is currently not possible to accurately describe this type using Luadoc.
---A table with alternating values: color in format of `{r, g, b}` and text which should be drawn using that color.
---Example: `{{1, 0, 0}, "red", {0, 1, 0}, "green", {1, 1, 1}, "white"}`
---@alias ColoredText table

local utf8 = require("utf8")
local json = require("com.json")

local utils = {}



---Loads a file from a given path and returns its contents, or `nil` if the file has not been found.
---@param path string The path to the file.
---@return string?
function utils.loadFile(path)
	local file, err = io.open(path, "r")
	if not file then
		print(string.format("WARNING: Error during loading: \"%s\" (%s): expect errors!", path, err))
		return
	end
	io.input(file)
	local contents = io.read("*a")
	io.close(file)
	return contents
end

---Saves a file to the given path with the given contents. Errors out if the file cannot be created.
---@param path string The path to the file.
---@param data string The contents of the file.
function utils.saveFile(path, data)
	local file = io.open(path, "w")
	assert(file, string.format("SAVE FILE FAIL: %s", path))
	io.output(file)
	io.write(data)
	io.close(file)
end



---Loads a file from a given path and interprets it as JSON data. Errors out if the file does not exist or does not contain valid JSON data.
---@param path string The path to the file.
---@return table?
function utils.loadJson(path)
	local contents = utils.loadFile(path)
	if not contents then
		return
	end
	local success, data = pcall(function() return json.decode(contents) end)
	assert(success, string.format("JSON error: %s: %s", path, data))
	assert(data, string.format("Could not JSON-decode: %s, error in file contents", path))
	return data
end

---Saves a file to the given path with the given contents, converted and beautified in JSON format. Errors out if the file cannot be created.
---@param path string The path to the file.
---@param data table The contents of the file.
function utils.saveJson(path, data)
	print("Saving JSON data to " .. path .. "...")
	utils.saveFile(path, utils.jsonBeautify(json.encode(data)))
end



-- This function allows to load images from external sources.
-- This is an altered code from https://love2d.org/forums/viewtopic.php?t=85350#p221460

---Opens an image file and returns its data. Returns `nil` if the file has not been found.
---@param path string The path to the file.
---@return love.ImageData?
function utils.loadImageData(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			data = love.filesystem.newFileData(data, "tempname")
			data = love.image.newImageData(data)
			return data
		end
	end
end



---Opens an image file and constructs `love.Image` from it. Errors out if the file has not been found.
---@param path string The path to the file.
---@return love.Image
function utils.loadImage(path)
	local imageData = utils.loadImageData(path)
	assert(imageData, string.format("LOAD IMAGE FAIL: %s", path))
	local image = love.graphics.newImage(imageData)
	return image
end



-- This function allows to load sounds from external sources.
-- This is an altered code from the above function.

---Opens a sound file and returns its sound data. Returns `nil` if the file has not been found.
---@param path string The path to the file.
---@return love.SoundData?
function utils.loadSoundData(path)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			-- to make everything work properly, we need to get the extension from the path, because it is used
			-- source: https://love2d.org/wiki/love.filesystem.newFileData
			local t = utils.strSplit(path, ".")
			local extension = t[#t]
			data = love.filesystem.newFileData(data, "tempname." .. extension)
			data = love.sound.newSoundData(data)
			return data
		end
	end
end



---Opens a sound file and constructs `love.Source` from it. Errors out if the file has not been found.
---@param path string The path to the file.
---@param type string How the sound should be loaded: `static` or `stream`.
---@return love.Source
function utils.loadSound(path, type)
	local soundData = utils.loadSoundData(path)
	assert(soundData, string.format("LOAD SOUND FAIL: %s", path))
	local sound = love.audio.newSource(soundData, type)
	return sound
end



-- This function allows to load fonts from external sources.
-- This is an altered code from the above function.

---Opens a font file and returns its font data. Returns `nil` if the file has not been found.
---@param path string The path to the file.
---@param size integer? The size of the font, in pixels. Defaults to LOVE-specified 12 pixels.
---@return love.Rasterizer?
function utils.loadFontData(path, size)
	local f = io.open(path, "rb")
	if f then
		local data = f:read("*all")
		f:close()
		if data then
			data = love.filesystem.newFileData(data, "tempname")
			data = love.font.newRasterizer(data, size)
			return data
		end
	end
end



---Opens a fond file and constructs `love.Font` from it. Errors out if the file has not been found.
---@param path string The path to the file.
---@param size integer? The size of the font, in pixels. Defaults to LOVE-specified 12 pixels.
---@return love.Font
function utils.loadFont(path, size)
	local fontData = utils.loadFontData(path, size)
	assert(fontData, string.format("LOAD FONT FAIL: %s", path))
	local font = love.graphics.newFont(fontData)
	return font
end



---Returns a list of directories and/or files in a given path.
---@param path string The path to the folder of which contents should be checked.
---@param filter string? `"dir"` will only list directories, `"file"` will only list files, `"all"` (default) will list both.
---@param extFilter string? If provided, files will have to end with this string in order to be listed. For example, `".json"` will only list `.json` files.
---@param recursive boolean? If set, files and directories will be checked recursively. Otherwise, only directories and files in this exact folder will be listed.
---@param pathRec string? Internal usage. Don't set.
---@return table
function utils.getDirListing(path, filter, extFilter, recursive, pathRec)
	-- filter can be "all", "dir" for directories only or "file" for files only.
	filter = filter or "all"
	pathRec = pathRec or ""

	local result = {}
	-- If it's compiled /fused/, this piece of code is needed to be able to read the external files
	if love.filesystem.isFused() then
		local success = love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), _FSPrefix)
		if not success then
			local msg = string.format("Failed to read contents of folder: \"%s\". Report this error to a developer.", path)
			error(msg)
		end
	end
	-- Now we can access the directory regardless of whether it's fused or not.
	local items = love.filesystem.getDirectoryItems(path .. "/" .. pathRec)
	-- Each folder will get a / character on the end BUT ONLY IN "ALL" FILTER so it's easier to tell whether this is a file or a directory.
	for i, item in ipairs(items) do
		local p = path .. "/" .. pathRec .. item
		if love.filesystem.getInfo(p).type == "directory" then
			if filter == "all" then
				table.insert(result, pathRec .. item .. "/")
			elseif filter == "dir" then
				table.insert(result, pathRec .. item)
			end
			if recursive then
				for j, file in ipairs(utils.getDirListing(path, filter, extFilter, true, pathRec .. item .. "/")) do
					table.insert(result, file)
				end
			end
		else
			if filter == "all" or filter == "file" and (not extFilter or utils.strEndsWith(item, extFilter)) then
				table.insert(result, pathRec .. item)
			end
		end
	end
	-- Unmount it so we don't get into safety problems.
	if pathRec == "" then
		love.filesystem.unmount(love.filesystem.getSourceBaseDirectory())
	end
	return result
end



---Adds all entries from `t2` to the table `t1`. Duplicates are not removed.
---@param t1 table The first table.
---@param t2 table The second table.
function utils.tableAddInplace(t1, t2)
	for i, v in ipairs(t2) do
		table.insert(t1, v)
	end
end



---Returns `true` if both tables are identical in contents. Shallow check is used.
---@param t1 table The first table.
---@param t2 table The second table to be compared with the first table.
function utils.areTablesIdentical(t1, t2)
	for i, n in pairs(t1) do
		if t2[i] ~= n then
			return false
		end
	end
	for i, n in pairs(t2) do
		if t1[i] ~= n then
			return false
		end
	end
	return true
end



---Returns `true` if the provided value is in the table.
---@param t table The table to be checked.
---@param v any The value to be checked. The function will return `true` if this value is inside the `t` table.
---@return boolean
function utils.isValueInTable(t, v)
	for i, n in pairs(t) do
		if n == v then
			return true
		end
	end
	return false
end



---Returns an index of the provided weight list, randomly picked from that list.
---For example, providing `{1, 2, 3}` will return `0` 1/6 of the time, `1` 2/6 of the time and `2` 3/6 of the time.
---@param weights table A list of integers, which depict the weights.
---@return integer
function utils.weightedRandom(weights)
	local t = 0
	for i, w in ipairs(weights) do
		t = t + w
	end
	local rnd = math.random(t) -- from 1 to t, inclusive, integer!!
	local i = 1
	while rnd > weights[i] do
		rnd = rnd - weights[i]
		i = i + 1
	end
	return i
end



---Splits a string `s` with the delimiter being `k` and returns a list of results.
---If Colored Text is passed, the result will be a list of Colored Texts.
---@param s string|ColoredText A string or LOVE Colored Text to be split.
---@param k string A delimiter which determines where to split `s`.
---@return string[]|ColoredText[]
function utils.strSplit(s, k)
	local result = {}
	if type(s) == "string" then
		local l = k:len()
		while true do
			local n = s:find("%" .. k)
			if n then
				table.insert(result, s:sub(1, n - 1))
				s = s:sub(n + l)
			else
				table.insert(result, s)
				return result
			end
		end
	elseif type(s) == "table" then
		-- We are splitting a colored text.
		-- Split each chunk separately and give it the same color.
		for i = 2, #s, 2 do
			local color = s[i - 1]
			local substrs = utils.strSplit(s[i], k)
			for j, substr in ipairs(substrs) do
				-- The first chunk of this color should be merged with the last chunk of the previous color.
				-- Otherwise, create a new chunk.
				if j > 1 or #result == 0 then
					table.insert(result, {})
				end
				table.insert(result[#result], color)
				table.insert(result[#result], substr)
			end
		end
		return result
	end
	error(string.format("Illegal input type for `utils.strSplit()`: %s (type %s, expected: string or table)", s, type(s)))
end



---Returns `true` if the string `s` starts with the clause `c`.
---@param s string The string to be searched.
---@param c string The expected beginning of the string `s`.
---@return boolean
function utils.strStartsWith(s, c)
	return s:sub(1, c:len()) == c
end



---Returns `true` if the string `s` ends with the clause `c`.
---@param s string The string to be searched.
---@param c string The expected ending of the string `s`.
---@return boolean
function utils.strEndsWith(s, c)
	return s:sub(s:len() - c:len() + 1) == c
end



---Combines a table of strings together to produce a string and returns the result.
---Deprecated, please use `table.concat` instead.
---@param t table A table of strings to be combined.
---@param k string A delimiter which will separate the terms.
---@return string
function utils.strJoin(t, k)
	local s = ""
	for i, n in ipairs(t) do
		if i > 1 then s = s .. k end
		s = s .. n
	end
	return s
end



---Trims whitespace from both the beginning and the end of a given string, and returns the result.
---Currently supported whitespace characters are `" "` and `"\t"`.
---@param s string A string to be truncated.
---@return string
function utils.strTrim(s)
	-- truncate leading whitespace
	while s:sub(1, 1) == " " or s:sub(1, 1) == "\t" do
        s = s:sub(2)
    end
	-- truncate trailing whitespace
	while s:sub(s:len(), s:len()) == " " or s:sub(s:len(), s:len()) == "\t" do
        s = s:sub(1, s:len() - 1)
    end

	return s
end



---Trims a line from a trailing comment.
---The only supported comment marker is `//`.
---
---Example: `"abcdef   // ghijkl"` will be truncated to `"abcdef"`.
---@param s string A string to be truncated.
---@return string
function utils.strTrimComment(s)
	-- truncate the comment part and trim
	return utils.strTrim(utils.strSplit(s, "//")[1])
end



---Strips the formatted text from formatting, if exists.
---@param s string|table A formatted string. If an unformatted string is passed, this function returns that string.
---@return string
function utils.strUnformat(s)
	if type(s) == "table" then
		local t = ""
		for i = 1, #s / 2 do
			t = t .. s[i * 2]
		end
		return t
	else
		return s
	end
end



---Checks whether the whole string is inside a single pair of brackets.
---For example, `(abcdef)` and `(abc(def))` will return `true`, but `(ab)cd(ef)` and `a(bcdef)` will return `false`.
---@param s string The string to be checked.
---@return boolean
function utils.strIsInWholeBracket(s)
	if s:sub(1, 1) ~= "(" or s:sub(s:len()) ~= ")" then
		return false
	end
	
	local pos = 2
	local brackets = 1

	-- Test whether this is the same bracket at the beginning and at the end.
	while pos < s:len() do
		-- Get the character.
		local c = s:sub(pos, pos)
		-- Update the bracket count.
		if c == "(" then
			brackets = brackets + 1
		elseif c == ")" then
			brackets = brackets - 1
		end
		-- If we're out of the root bracket, return false.
		if brackets == 0 then
			return false
		end
		pos = pos + 1
	end
	
	return true
end



---A simple function which makes JSON formatting nicer.
---@param s string Raw JSON input to be formatted.
---@return string
function utils.jsonBeautify(s)
	local indent = 0
	local ret = "" -- returned string
	local ln = "" -- current line
	local strMode = false -- if we're inside a string chain (")

	for i = 1, s:len() do
		local pc = s:sub(i-1, i-1) -- previous character
		local c = s:sub(i, i) -- this character
		local nc = s:sub(i+1, i+1) -- next character
		local strModePrev = false -- so we don't switch this back off on the way

		if not strMode and c == "\"" then
			strMode = true
			strModePrev = true
		end
		if strMode then -- strings are not JSON syntax, so they omit the formatting rules
			ln = ln .. c
			if not strModePrev and c == "\"" and pc ~= "\\" then
                strMode = false
            end
		else
			if (c == "]" or c == "}") and not (pc == "[" or pc == "{") then
				indent = indent - 1
				ret = ret .. ln .. "\n"
				ln = string.rep("\t", indent)			-- NEWLINE
			end
			ln = ln .. c
			if c == ":" then
				ln = ln .. " " -- spacing after colons, for more juice
			end
			if c == "," then
				ret = ret .. ln .. "\n"
				ln = string.rep("\t", indent)			-- NEWLINE
			end
			if (c == "[" or c == "{") and not (nc == "]" or nc == "}") then
				indent = indent + 1
				ret = ret .. ln .. "\n"
				ln = string.rep("\t", indent)			-- NEWLINE
			end
		end
	end

	ret = ret .. ln .. "\n"

	return ret
end



---Removes all dead objects from the table `t`. By dead objects we mean objects that have their `delQueue` field set to `true`.
---The table must be a list-like. Other keysets are not supported.
---@param t table The table to be cleaned up.
function utils.removeDeadObjects(t)
	for i = #t, 1, -1 do
		if t[i].delQueue then
			table.remove(t, i)
		end
	end
end



---Clamps a number `n` into range `<a, b>`.
---@param n number The number to be clamped.
---@param a number? The minimum possible value. Defaults to `0`.
---@param b number? The maximum possible value. Defaults to `1`.
---@return number
function utils.clamp(n, a, b)
	return math.min(math.max(n, a or 0), b or 1)
end

---Interpolates a number from `a` to `b` based on time `t`.
---When `t = 0`, `a` is returned, and when `t = 1`, `b` is returned.
---@param a number The value for `t = 0`.
---@param b number The value for `t = 1`.
---@param t number The time parameter.
---@return number
function utils.lerp(a, b, t)
	return a * (1 - t) + b * t
end

function utils.lerpClamped(a, b, t)
	return utils.lerp(a, b, math.min(math.max(t, 0), 1))
end

function utils.lerp2(a, b, t1, t2, t)
	return utils.lerp(a, b, (t - t1) / (t2 - t1))
end

function utils.lerp2Clamped(a, b, t1, t2, t)
	return utils.lerp(a, b, math.min(math.max((t - t1) / (t2 - t1), 0), 1))
end



---Returns `true` if two ranges of numbers intersect (at least one number is common).
---@param s1 number The start of the first range.
---@param e1 number The end of the first range.
---@param s2 number The start of the second range.
---@param e2 number The end of the second range.
---@return boolean
function utils.doRangesIntersect(s1, e1, s2, e2)
	return s1 <= e2 and s2 <= e1
end



function utils.isPosInBox(x, y, w, h, px, py)
	assert(w >= 0 and h >= 0, "Illegal boxes passed to `_Utils.isPosInBox()`! You must normalize the boxes first using `_Utils.normalizeBox(x, y, w, h)`.")
	return px >= x and py >= y and px <= x + w and py <= y + h
end



---Returns `true` if the first box intersects the second box in any way.
---@param x1 number X position of the top left corner of the first box.
---@param y1 number Y position of the top left corner of the first box.
---@param w1 number Width of the first box.
---@param h1 number Height of the first box.
---@param x2 number X position of the top left corner of the second box.
---@param y2 number Y position of the top left corner of the second box.
---@param w2 number Width of the second box.
---@param h2 number Height of the second box.
---@return boolean
function utils.doBoxesIntersect(x1, y1, w1, h1, x2, y2, w2, h2)
	assert(w1 >= 0 and h1 >= 0 and w2 >= 0 and h2 >= 0, "Illegal boxes passed to `_Utils.doBoxesIntersect()`! You must normalize the boxes first using `_Utils.normalizeBox(x, y, w, h)`.")
	return utils.doRangesIntersect(x1, x1 + w1, x2, x2 + w2) and utils.doRangesIntersect(y1, y1 + h1, y2, y2 + h2)
end



---Adds a new text segment to the provided chunk of colored text.
---@param ctext ColoredText The colored text to be added to.
---@param text string|ColoredText The text or colored text to be added.
---@param color [number, number, number]? The color of the new segment. If not specified, color of the previous segment will be used.
function utils.ctextAdd(ctext, text, color)
	if type(text) == "table" then
		utils.tableAddInplace(ctext, text)
	else
		local prevColor = ctext[#ctext - 1]
		local sameColor = color and prevColor and utils.areTablesIdentical(color, prevColor)
		if color and not sameColor then
			table.insert(ctext, color)
			table.insert(ctext, text)
		else
			if #ctext == 0 then
				-- If the colored text was empty, the first segment will be white.
				table.insert(ctext, {1, 1, 1})
				table.insert(ctext, text)
			else
				ctext[#ctext] = ctext[#ctext] .. text
			end
		end
	end
end



---Returns a substring of Colored Text.
---@param ctext ColoredText The colored text to be split.
---@param i integer The first character, 1-indexed.
---@param j integer The last character to be included in the returned string, 1-indexed, inclusive.
---@return ColoredText
function utils.ctextSub(ctext, i, j)
	local n = 0
	local result = {}
	for k = 1, #ctext, 2 do
		local color = ctext[k]
		local text = ctext[k + 1]
		local l = #text
		if i <= n + l then
			local subtext = text:sub(math.max(i - n, 1), math.min(j - n, l))
			utils.ctextAdd(result, subtext, color)
			if j <= n + l then
				break
			end
		end
		n = n + l
	end
	return result
end



---Returns the total length of Colored Text in bytes.
---@param ctext ColoredText The colored text to be calculated length of.
---@return integer
function utils.ctextLen(ctext)
	local l = 0
	for k = 1, #ctext, 2 do
		l = l + #ctext[k + 1]
	end
	return l
end



---Returns whether the provided value is a valid colored text.
---Empty tables are not considered colored text.
---@param value any The value to be checked.
---@return boolean
function utils.tableIsCtext(value)
	if type(value) ~= "table" or #value == 0 then
		return false
	end

	for i, v in ipairs(value) do
		if i % 2 == 1 then
			-- Must be a color.
			if type(v) ~= "table" or #v ~= 3 then
				return false
			end
		else
			-- Must be a string.
			if type(v) ~= "string" then
				return false
			end
		end
	end
	return true
end



return utils
