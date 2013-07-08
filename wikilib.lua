
local WP = minetest.get_worldpath().."/wiki"

local WIKI_FORMNAME = "wiki:wiki"

local WIN32, DIR_SEP

if os.getenv("WINDIR") then
	WIN32 = true
	DIR_SEP = "\\"
else
	WIN32 = false
	DIR_SEP = "/"
end

local function mkdir(dir)
	local f = io.open(dir..DIR_SEP..".dummy")
	if f then
		f:close()
	else
		if WIN32 then
			dir = dir:gsub("/", "\\")
		else
			dir = dir:gsub("\\", "/")
		end
		os.execute("mkdir \""..dir.."\"")
		local f = io.open(dir..DIR_SEP..".dummy", "w")
		if f then
			f:write("DO NOT DELETE!!!\n")
			f:close()
		end
	end
end

mkdir(WP)
mkdir(WP.."/users")

local function name_to_filename(name)

	name = name:gsub("[^A-Za-z0-9-]", function(c)
		if c == " " then
			return "_"
		else
			return ("%%%02X"):format(c:byte(1))
		end
	end)
	return name:lower()

end

local function get_page_path(name, player) --> path, is_file

	if name:sub(1, 1) == "." then
		local text = wikilib.internal_pages[name] or wikilib.internal_pages[".NotFound_Internal"]
		return text, false
	elseif name:sub(1, 1) == ":" then
		if name:match("^:[0-9]?$") then
			local n = tonumber(name:sub(2,2)) or 0
			path = "users/"..player.."/page"..n
			mkdir(WP.."/users/"..player)
		elseif name:match("^:.-:[1-9]$") then
			local user, n = name:match("^:(.-):([1-9])$")
			path = "users/"..user.."/page"..n
			mkdir(WP.."/users/"..user)
		else
			return wikilib.internal_pages[".BadPageName"], false
		end
	else
		path = name_to_filename(name)
	end

	return WP.."/"..path, true

end

local function find_links(lines) --> links
	local links = { }
	local links_n = 0
	for _,line in ipairs(lines) do
		for link in line:gmatch("%[(.-)%]") do
			links_n = links_n + 1
			links[links_n] = link
		end
	end
	return links
end

local function load_page(name, player) --> text, links
	local path, is_file = get_page_path(name, player)
	local f
	if is_file then
		f = io.open(path)
		if not f then
			f = strfile.open(wikilib.internal_pages[".NotFound"])
		end
	else
		f = strfile.open(path)
	end
	local lines = { }
	local lines_n = 0
	for line in f:lines() do
		lines_n = lines_n + 1
		lines[lines_n] = line
	end
	f:close()
	local text = table.concat(lines, "\n")
	local links = find_links(lines)
	return text, links
end

local function save_page(name, player, text)

	local path, is_file = get_page_path(name, player)

	if not is_file then return end

	local f = io.open(path, "w")
	if not f then return end

	f:write(text)

	f:close()

end

local esc = minetest.formspec_escape

local function show_wiki_page(player, name)

	if name == "" then name = "Main" end

	local text, links = load_page(name, player)

	local buttons = ""
	local bx = 0
	local by = 7.5

	for i, link in ipairs(links) do
		if (i % 5) == 0 then
			bx = 0
			by = by + 0.3
		end
		link = esc(link)
		buttons = buttons..(("button[%f,%f;2.4,0.3;page_%s;%s]"):format(bx, by, link, link))
		bx = bx + 2.4
	end

	local toolbar

	if is_user or minetest.check_player_privs(player, {wiki=true}) then
		toolbar = "button[0,9;2.4,1;save;Save]"
	else
		toolbar = "label[0,9;You are not authorized to edit this page.]"
	end

	minetest.show_formspec(player, WIKI_FORMNAME, ("size[12,10]"
		.. "field[0,1;11,1;page;Page;"..esc(name).."]"
		.. "button[11,1;1,0.5;go;Go]"
		.. "textarea[0,2;12,6;text;"..esc(name)..";"..esc(text).."]"
		.. buttons
		.. toolbar
	))

end

minetest.register_node("wiki:wiki", {
	description = "Wiki",
	tiles = { "default_wood.png", "default_wood.png", "default_bookshelf.png" },
	groups = { choppy=3, oddly_breakable_by_hand=2, flammable=3 },
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Wiki")
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		if clicker then
			show_wiki_page(clicker:get_player_name(), "Main")
		end
	end,
})

minetest.register_privilege("wiki", {
	description = "Allow editing wiki pages",
	give_to_singleplayer = true,
})

local BS = "default:bookshelf"
local BSL = { BS, BS, BS }
minetest.register_craft({
	output = "wiki:wiki",
	recipe = { BSL, BSL, BSL },
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if (not formname) or (formname ~= WIKI_FORMNAME) then return end
	local plname = player:get_player_name()
	if fields.save then
		save_page(fields.page, plname, fields.text)
		show_wiki_page(plname, fields.page)
	elseif fields.go then
		show_wiki_page(plname, fields.page)
	else
		for k in pairs(fields) do
			if type(k) == "string" then
				local name = k:match("^page_(.*)")
				if name then
					show_wiki_page(plname, name)
				end
			end
		end
	end
end)
