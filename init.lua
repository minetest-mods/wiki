
local WP = minetest.get_worldpath().."/wiki"

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

local function parse_wiki_file(f)
	local text = ""
	local links = { }
	local links_n = 0
	for line in f:lines() do
		for link in line:gmatch("<([^>]*)>") do
			links_n = links_n + 1
			links[links_n] = link
		end
		text = text..line.."\n"
	end
	return text, links
end

local function create_wiki_page(name, text)

	local fn = WP.."/"..name_to_filename(name)

	local f = io.open(fn, "w")
	if not f then return end

	local nl = ""

	if text:sub(-1) ~= "\n" then nl = "\n" end

	f:write(text..nl)

	f:close()

end

local function get_wiki_page(name)

	local fn = WP.."/"..name_to_filename(name)

	local f = io.open(fn)

	local text

	if f then
		text, links = parse_wiki_file(f)
	else
		text = "This page does not exist yet."
		links = { }
	end

	local buttons = ""
	local bx = 0
	local by = 0

	for i, link in ipairs(links) do
		if (i % 5) == 0 then
			bx = 0
			by = by + 0.5
		end
		link = esc(link)
		buttons = buttons..(("button[%f,%f;3,0.5;page_%s;%s]"):format(bx, by, link, link))
		bx = bx + 2.4
	end

	--local esc = minetest.formspec_escape
	local esc = function(x) return x end

	return ("size[12,9]"
		.. "field[0,1;11,1;page;Page;"..esc(name).."]"
		.. "button[11,1;1,0.5;go;Go]"
		.. "textarea[0,2;12,7;text;"..esc(name)..";"..esc(text).."]"
		.. buttons
		.. "button[0,8;3,1;save;Save]"
	)

end

local function set_wiki_page(meta, name)
	meta:set_string("formspec", get_wiki_page(name))
	meta:set_string("wiki.page", name)
end

minetest.register_node("wiki:personal_wiki", {
	description = "Wiki",
	tiles = { "default_wood.png", "default_wood.png", "default_bookshelf.png" },
	groups = { choppy=3, oddly_breakable_by_hand=2, flammable=3 },
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Wiki")
		set_wiki_page(meta, "Main")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		if fields.save then
			local name = meta:get_string("wiki.page")
			create_wiki_page(name, fields.text)
		elseif fields.go then
			set_wiki_page(meta, fields.page)
		end
	end,
})

local BS = "default:bookshelf"
local BSL = { BS, BS, BS }
minetest.register_craft({
	output = "wiki:wiki",
	recipe = { BSL, BSL, BSL },
})
