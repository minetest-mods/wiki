
local WP = minetest.get_worldpath().."/wiki"

local internal_pages = {
----------------------------------------------------------------
----------------------------------------------------------------
[".Intro"] = [[
Thank you for using the Wiki Mod.

This is a mod that allows one to edit pages via a block. You
can use it to document interesting places in a server, to provide
a place to post griefing reports, or any kind of text you want.

To create a new page, enter the name in the field at the top of the
form, then click "Go". If the page already exists, it's contents will
be displayed. Edit the page as you see fit, then click on "Save" to
write the changes to disk.

Please note that page names starting with a dot ('.') are reserved
for internal topics such as this one. Users cannot edit/create such
pages from the mod interface.

See also:
  * [.Tags]
  * [.License]
]],
----------------------------------------------------------------
----------------------------------------------------------------
[".Tags"] = [[
The wiki supports some special tags.

You can place hyperlinks to other pages in the Wiki, by surrounding
text in square brackets (for example, [.Intro]). Such links will
appear at the bottom of the form.

See also:
  * [.Intro]
]],
----------------------------------------------------------------
----------------------------------------------------------------
[".License"] = [[
Wiki Mod for Minetest - License
-------------------------------

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.

See also:
  * [.Intro]
]],
----------------------------------------------------------------
----------------------------------------------------------------
[".NotFound"] = [[
The specified internal page cannot be found. You may want to:

  * Go back to [Main].
  * Go to [.Intro].
]],
----------------------------------------------------------------
----------------------------------------------------------------
}

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
	return name:lower()

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

	if name:sub(1, 1) == "." then return end

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

	local text, links

	if name:sub(1, 1) == "." then

		text = internal_pages[name] or internal_pages[".NotFound"]
		links = find_links(text)

	else

		local fn = WP.."/"..name_to_filename(name)

		local f = io.open(fn)

		if f then
			text, links = parse_wiki_file(f)
			f:close()
		else
			if name == "Main" then
				text = internal_pages[".Intro"]
				links = find_links(text)
			else
				text = "This page does not exist yet."
				links = { }
			end
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
