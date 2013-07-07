
local WP = minetest.get_worldpath().."/wiki"

local DEFAULT_MAIN_PAGE_TEXT = [[
Thank you for using the Wiki Mod.

This is a mod that allows one to edit pages via a block. You
can use it to document interesting places in a server, to provide
a place to post griefing reports, or any kind of text you want.

You can place hyperlinks to other pages in the Wiki, by surrounding
text in square brackets (for example, [this is a link]). Such links
appear at the bottom of the form.
]]

local WIKI_FORMNAME = "wiki:wiki"

local f = io.open(WP.."/.dummy")
if f then
	f:close()
else
	os.execute("mkdir \""..WP.."\"")
	local f = io.open(WP.."/.dummy", "w")
	if f then
		f:write("DO NOT DELETE!!!\n")
		f:close()
	end
end
f = nil

local function name_to_filename(name)

	name = name:gsub("[^A-Za-z0-9-]", function(c)
		if c == " " then
			return "_"
		else
			return ("%%%02X"):format(c:byte(1))
		end
	end)
	return name

end

local function filename_to_name(filename)

	filename = name:gsub("_", " "):gsub("%%[0-9a-fA-F][0-9a-fA-F]", function(c)
		return string.char(tonumber(c:sub(2, 3), 16))
	end)
	return filename

end

local function find_links(text)
	local links = { }
	for link in text:gmatch("%[(.-)%]") do
		links[#links + 1] = link
	end
	return links
end

local function parse_wiki_file(f)
	local text = ""
	local links_n = 0
	for line in f:lines() do
		text = text..line.."\n"
	end
	return text, find_links(text)
end

local function create_wiki_page(name, text)

	if name == "" then return end

	local fn = WP.."/"..name_to_filename(name)

	local f = io.open(fn, "w")
	if not f then return end

	local nl = ""

	if text:sub(-1) ~= "\n" then nl = "\n" end

	f:write(text..nl)

	f:close()

end

local function get_wiki_page(name, player)

	if name == "" then name = "Main" end

	local fn = WP.."/"..name_to_filename(name)

	local f = io.open(fn)

	local text

	if f then
		text, links = parse_wiki_file(f)
		f:close()
	else
		if name == "Main" then
			text = DEFAULT_MAIN_PAGE_TEXT
			links = find_links(text)
		else
			text = "This page does not exist yet."
			links = { }
		end
	end

	local buttons = ""
	local bx = 0
	local by = 7.5

	local esc = minetest.formspec_escape

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

	if minetest.check_player_privs(player, {wiki=true}) then
		toolbar = "button[0,9;2.4,1;save;Save]"
	else
		toolbar = "label[0,9;You are not authorized to edit the wiki.]"
	end

	return ("size[12,10]"
		.. "field[0,1;11,1;page;Page;"..esc(name).."]"
		.. "button[11,1;1,0.5;go;Go]"
		.. "textarea[0,2;12,6;text;"..esc(name)..";"..esc(text).."]"
		.. buttons
		.. toolbar
	)

end

local function show_wiki_page(player, name)
	local formspec = get_wiki_page(name, player)
	minetest.show_formspec(player, WIKI_FORMNAME, formspec)
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
		create_wiki_page(fields.page, fields.text)
		show_wiki_page(plname, fields.page)
	elseif fields.go then
		show_wiki_page(plname, fields.page)
	elseif fields.back then
		show_wiki_page(plname, prev)
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
