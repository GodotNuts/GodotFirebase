tool
extends DocExporter

var plugin: EditorPlugin

var label: RichTextLabel
var class_docs: Dictionary

var editor_settings: EditorSettings
var theme: Theme
var class_list := Array(ClassDB.get_class_list()) + [
	"Variant", "bool", "int", "float",
	"String", "Vector2", "Rect2", "Vector3",
	"Transform2D", "Plane", "Quat", "AABB",
	"Basis", "Transform", "Color", "NodePath",
	"RID", "Object", "Dictionary", "Array",
	"PoolByteArray", "PoolIntArray", "PoolRealArray",
	"PoolStringArray", "PoolVector2Array",
	"PoolVector3Array", "PoolColorArray"
]

var section_lines := []
var description_line := 0
var signal_line := {}
var method_line := {}
var property_line := {}
var enum_line := {}
var constant_line := {}


var doc_font: Font
var doc_bold_font: Font
var doc_title_font: Font
var doc_code_font: Font

var title_color: Color
var text_color: Color
var headline_color: Color
var base_type_color: Color
var comment_color: Color
var symbol_color: Color
var value_color: Color
var qualifier_color: Color
var type_color: Color


func _generate(doc: ClassDocItem) -> String:
	var is_current: bool = label.is_visible_in_tree()
	var link_color_text := title_color.to_html()
	section_lines.clear()
	if is_current:
		signal_line.clear()
		method_line.clear()
		property_line.clear()
		enum_line.clear()
		constant_line.clear()
	
	label.visible = true
	label.clear()
	
	# Class Name
	if is_current:
		section_lines.append(["Top", 0])
	label.push_font(doc_title_font)
	label.push_color(title_color)
	label.add_text("Class: ")
	label.push_color(headline_color)
	add_text(doc.name)
	label.pop()
	label.pop()
	label.pop()
	label.add_text("\n")
	
	# Ascendance
	if doc.base != "":
		label.push_color(title_color)
		label.push_font(doc_font)
		label.add_text("Inherits: ")
		label.pop()
		
		var inherits = doc.base
		
		while inherits != "":
			add_type(inherits, "")
			inherits = plugin.get_parent_class(inherits)
			
			if inherits != "":
				label.add_text(" < ")
		
		label.pop()
		label.add_text("\n")
	
	# Descendents
	var found := false
	var prev := false
	for name in class_docs:
		if class_docs[name].base == doc.name:
			if not found:
				label.push_color(title_color)
				label.push_font(doc_font)
				label.add_text("Inherited by: ")
				label.pop()
				found = true
			
			if prev:
				label.add_text(" , ")
			
			add_type(name, "")
			prev = true
	if found:
		label.pop()
		label.add_text("\n")
	
	label.add_text("\n")
	label.add_text("\n")
	
	# Brief description
	if doc.brief != "":
		label.push_color(text_color)
		label.push_font(doc_bold_font)
		label.push_indent(1)
		add_text(doc.brief)
		label.pop()
		label.pop()
		label.pop()
		label.add_text("\n")
		label.add_text("\n")
		label.add_text("\n")
	
	if doc.description != "":
		if is_current:
			section_lines.append(["Description", label.get_line_count() - 2])
			description_line = label.get_line_count() - 2
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Description")
		label.pop()
		label.pop()
		
		label.add_text("\n")
		label.add_text("\n")
		label.push_color(text_color)
		label.push_font(doc_font)
		label.push_indent(1)
		add_text(doc.description)
		label.pop()
		label.pop()
		label.pop()
		label.add_text("\n")
		label.add_text("\n")
		label.add_text("\n")
	
	# Online tutorials
	if doc.tutorials.size():
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Online Tutorials")
		label.pop()
		label.pop()
		
		label.push_indent(1)
		label.push_font(doc_code_font)
		label.add_text("\n")
		
		for tutorial in doc.tutorials:
			var link: String = tutorial
			var linktxt: String = tutorial
			var seppos := link.find("//")
			if seppos != -1:
				link = link.right(seppos + 2)
			
			label.push_color(symbol_color)
			label.append_bbcode("[url=" + linktxt + "]" + link + "[/url]")
			label.pop()
			label.add_text("\n")
		
		label.pop()
		label.pop()
		label.add_text("\n")
		label.add_text("\n")
	
	# Properties overview
	var skip_methods := []
	var property_descr := false
	
	if doc.properties.size():
		if is_current:
			section_lines.append(["Properties", label.get_line_count() - 2])
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Properties")
		label.pop()
		label.pop()
		
		label.add_text("\n")
		label.push_font(doc_code_font)
		label.push_indent(1)
		label.push_table(2)
		label.set_table_column_expand(1, true, 1)
		
		for property in doc.properties:
			property_line[property.name] = label.get_line_count() - 2 #gets overridden if description
			label.push_cell()
			label.push_align(RichTextLabel.ALIGN_RIGHT)
			label.push_font(doc_code_font)
			add_type(property.type, property.enumeration)
			label.pop()
			label.pop()
			label.pop()
			
			var describe := false
			
			if property.setter != "":
				skip_methods.append(property.setter)
				describe = true
			if property.getter != "":
				skip_methods.append(property.getter)
				describe = true
			
			if property.description != "":
				describe = true
			
			label.push_cell()
			label.push_font(doc_code_font)
			label.push_color(headline_color)
			
			if describe:
				label.push_meta("@member " + property.name)
			
			add_text(property.name)
			
			if describe:
				label.pop()
				property_descr = true
			
			if property.default != "":
				label.push_color(symbol_color)
				label.add_text(" [default: ")
				label.pop()
				label.push_color(value_color)
				add_text(property.default)
				label.pop()
				label.push_color(symbol_color)
				label.add_text("]")
				label.pop()

			label.pop()
			label.pop()
			label.pop()

		label.pop() #table
		label.pop()
		label.pop() # font
		label.add_text("\n")
		label.add_text("\n")

	# Methods overview
	var method_descr := false
	var sort_methods: bool = editor_settings.get("text_editor/help/sort_functions_alphabetically")
	var methods := []
	
	for method in doc.methods:
		if skip_methods.has(method.name):
			if method.args.size() == 0 or (method.args.size() == 1 and method.return_type == "void"):
				continue
		methods.append(method)
	
	if methods.size():
		if sort_methods:
			methods.sort_custom(self, "sort_methods")
		if is_current:
			section_lines.append(["Methods", label.get_line_count() - 2])
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Methods")
		label.pop()
		label.pop()
		
		label.add_text("\n")
		label.push_font(doc_code_font)
		label.push_indent(1)
		label.push_table(2)
		label.set_table_column_expand(1, true, 1)
		
		var any_previous := false
		for _pass in 2:
			var m := []
			for method in methods:
				if (_pass == 0 and method.is_virtual) or (_pass == 1 and not method.is_virtual):
					m.append(method)
			
			if any_previous and not m.empty():
				label.push_cell()
				label.pop() #cell
				label.push_cell()
				label.pop() #cell
			
			var group_prefix := ""
			for i in m.size():
				var new_prefix: String = m[i].name.substr(0, 3)
				var is_new_group := false
				
				if i < m.size() - 1 and new_prefix == m[i + 1].name.substr(0, 3) and new_prefix != group_prefix:
					is_new_group = i > 0
					group_prefix = new_prefix
				elif group_prefix != "" and new_prefix != group_prefix:
					is_new_group = true
					group_prefix = ""
				
				if is_new_group and _pass == 1:
					label.push_cell()
					label.pop() #cell
					label.push_cell()
					label.pop() #cell
				
				if m[i].description != "":
					method_descr = true
				
				add_method(m[i], true)
			
			any_previous = !m.empty()
		
		label.pop() #table
		label.pop()
		label.pop() # font
		label.add_text("\n")
		label.add_text("\n")

	# Theme properties
#	if doc.theme_properties.size():
#
#		section_line.append(Pair<String, int>(TTR("Theme Properties"), label.get_line_count() - 2))
#		label.push_color(title_color)
#		label.push_font(doc_title_font)
#		label.add_text(TTR("Theme Properties"))
#		label.pop()
#		label.pop()
#
#		label.push_indent(1)
#		label.push_table(2)
#		label.set_table_column_expand(1, 1)
#
#		for int i = 0 i < doc.theme_properties.size() i++:
#
#			theme_property_line[doc.theme_properties[i].name] = label.get_line_count() - 2 #gets overridden if description
#
#			label.push_cell()
#			label.push_align(RichTextLabel.ALIGN_RIGHT)
#			label.push_font(doc_code_font)
#			//add_type(doc.theme_properties[i].type)
#			label.pop()
#			label.pop()
#			label.pop()
#
#			label.push_cell()
#			label.push_font(doc_code_font)
#			label.push_color(headline_color)
#			//add_text(doc.theme_properties[i].name)
#			label.pop()
#
#			if doc.theme_properties[i].default != "":
#				label.push_color(symbol_color)
#				label.add_text(" [" + TTR("default:") + " ")
#				label.pop()
#				label.push_color(value_color)
#				//add_text(_fix_constant(doc.theme_properties[i].default))
#				label.pop()
#				label.push_color(symbol_color)
#				label.add_text("]")
#				label.pop()
#			}
#
#			label.pop()
#
#			if doc.theme_properties[i].description != "":
#				label.push_font(doc_font)
#				label.add_text("  ")
#				label.push_color(comment_color)
#				//add_text(doc.theme_properties[i].description)
#				label.pop()
#				label.pop()
#			}
#			label.pop() # cell
#		}
#
#		label.pop() # table
#		label.pop()
#		label.add_text("\n")
#		label.add_text("\n")
#	}
#
	# Signals
	var signals := doc.signals.duplicate()
	if signals.size():
		if sort_methods:
			signals.sort()
		if is_current:
			section_lines.append(["Signals", label.get_line_count() - 2])
		
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Signals")
		label.pop()
		label.pop()
		
		label.add_text("\n")
		label.add_text("\n")
		
		label.push_indent(1)
		
		for _signal in signals:
			signal_line[_signal.name] = label.get_line_count() - 2 #gets overridden if description
			label.push_font(doc_code_font) # monofont
			label.push_color(headline_color)
			add_text(_signal.name)
			label.pop()
			label.push_color(symbol_color)
			label.add_text("(")
			label.pop()
			for j in _signal.args.size():
				label.push_color(text_color)
				if j > 0:
					label.add_text(", ")
				
				add_text(_signal.args[j].name)
				label.add_text(": ")
				add_type(_signal.args[j].type, _signal.args[j].enumeration)
				if _signal.args[j].default != "":
					label.push_color(symbol_color)
					label.add_text(" = ")
					label.pop()
					add_text(_signal.args[j].default)
				
				label.pop()
			
			label.push_color(symbol_color)
			label.add_text(")")
			label.pop()
			label.pop() # end monofont
			if _signal.description != "":
				label.push_font(doc_font)
				label.push_color(comment_color)
				label.push_indent(1)
				add_text(_signal.description)
				label.pop() # indent
				label.pop()
				label.pop() # font
			label.add_text("\n")
			label.add_text("\n")
		
		label.pop()
		label.add_text("\n")
	
	# Constants and enums
	if doc.constants.size():
		var enums := {}
		var constants := []
		for i in doc.constants.size():
			if doc.constants[i].enumeration != "":
				if not enums.has(doc.constants[i].enumeration):
					enums[doc.constants[i].enumeration] = []
				enums[doc.constants[i].enumeration].append(doc.constants[i])
			else:
				constants.append(doc.constants[i])
		
		# Enums
		if enums.size():
			section_lines.append(["Enumerations", label.get_line_count() - 2])
			label.push_color(title_color)
			label.push_font(doc_title_font)
			label.add_text("Enumerations")
			label.pop()
			label.pop()
			label.push_indent(1)
			
			label.add_text("\n")
			
			for e in enums:
				enum_line[e] = label.get_line_count() - 2
				
				label.push_color(title_color)
				label.add_text("enum  ")
				label.pop()
				label.push_font(doc_code_font)
				if (e.split(".").size() > 1) and (e.split(".")[0] == doc.name):
					e = e.split(".")[1]
				
				label.push_color(headline_color)
				label.add_text(e)
				label.pop()
				label.pop()
				label.push_color(symbol_color)
				label.add_text(":")
				label.pop()
				label.add_text("\n")
				
				label.push_indent(1)
				var enum_list: Array = enums[e]
				
				for _enum in enum_list:
					# Add the enum constant line to the constant_line map so we can locate it as a constant
					constant_line[_enum.name] = label.get_line_count() - 2
					
					label.push_font(doc_code_font)
					label.push_color(headline_color)
					add_text(_enum.name)
					label.pop()
					label.push_color(symbol_color)
					label.add_text(" = ")
					label.pop()
					label.push_color(value_color)
					add_text(_enum.value)
					label.pop()
					label.pop()
					if _enum.description != "":
						label.push_font(doc_font)
						#label.add_text("  ")
						label.push_indent(1)
						label.push_color(comment_color)
						add_text(_enum.description)
						label.pop()
						label.pop()
						label.pop() # indent
						label.add_text("\n")
					label.add_text("\n")
				
				label.pop()
				label.add_text("\n")
			
			label.pop()
			label.add_text("\n")
		
		# Constants
		if constants.size():
			section_lines.append(["Constants", label.get_line_count() - 2])
			label.push_color(title_color)
			label.push_font(doc_title_font)
			label.add_text("Constants")
			label.pop()
			label.pop()
			label.push_indent(1)
			
			label.add_text("\n")
			
			for i in constants.size():
#				constant_line[constants[i].name] = label.get_line_count() - 2
				label.push_font(doc_code_font)
				
				if constants[i].value.begins_with("Color(") and constants[i].value.ends_with(")"):
					var stripped: String = constants[i].value.replace(" ", "").replace("Color(", "").replace(")", "")
					var color := stripped.split_floats(",")
					if color.size() >= 3:
						label.push_color(Color(color[0], color[1], color[2]))
						var prefix := [0x25CF, ' ', 0]
						label.add_text(String(prefix))
						label.pop()
				
				label.push_color(headline_color)
				add_text(constants[i].name)
				label.pop()
				label.push_color(symbol_color)
				label.add_text(" = ")
				label.pop()
				label.push_color(value_color)
				add_text(constants[i].value)
				label.pop()
				
				label.pop()
				if constants[i].description != "":
					label.push_font(doc_font)
					label.push_indent(1)
					label.push_color(comment_color)
					add_text(constants[i].description)
					label.pop()
					label.pop()
					label.pop() # indent
					label.add_text("\n")
			
				label.add_text("\n")
			
			label.pop()
			label.add_text("\n")
	
	# Property descriptions
	if property_descr:
		section_lines.append(["Property Descriptions", label.get_line_count() - 2])
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Property Descriptions")
		label.pop()
		label.pop()
		
		label.add_text("\n")
		label.add_text("\n")
		
		for prop in doc.properties:
#			if doc.properties[i].overridden:
#				continue
			
			property_line[prop.name] = label.get_line_count() - 2
			label.push_table(2)
			label.set_table_column_expand(1, true, 1)
			
			label.push_cell()
			label.push_font(doc_code_font)
			add_type(prop.type, prop.enumeration)
			label.add_text(" ")
			label.pop() # font
			label.pop() # cell
			
			label.push_cell()
			label.push_font(doc_code_font)
			label.push_color(headline_color)
			add_text(prop.name)
			label.pop() # color
			
			if prop.default != "":
				label.push_color(symbol_color)
				label.add_text(" [default: ")
				label.pop() # color
				
				label.push_color(value_color)
				add_text(prop.default)
				label.pop() # color
				
				label.push_color(symbol_color)
				label.add_text("]")
				label.pop() # color
			
			label.pop() # font
			label.pop() # cell
			
			var method_map := {}
			for method in methods:
				method_map[method.name] = method
			
			if prop.setter != "":
				label.push_cell()
				label.pop() # cell
				
				label.push_cell()
				label.push_font(doc_code_font)
				label.push_color(text_color)
				if method_map.has(prop.setter) and method_map[prop.setter].args.size() > 1:
					# Setters with additional args are exposed in the method list, so we link them here for quick access.
					label.push_meta("@method " + prop.setter)
					label.add_text(prop.setter + "(value)")
					label.pop()
				else:
					label.add_text(prop.setter + "(value)")
				label.pop() # color
				label.push_color(comment_color)
				label.add_text(" setter")
				label.pop() # color
				label.pop() # font
				label.pop() # cell
				method_line[prop.setter] = property_line[prop.name]
			
			if prop.getter != "":
				label.push_cell()
				label.pop() # cell
				
				label.push_cell()
				label.push_font(doc_code_font)
				label.push_color(text_color)
				if method_map.has(prop.getter) and method_map[prop.getter].args.size() > 0:
					# Getters with additional args are exposed in the method list, so we link them here for quick access.
					label.push_meta("@method " + prop.getter)
					label.add_text(prop.getter + "()")
					label.pop()
				else:
					label.add_text(prop.getter + "()")
				label.pop() #color
				label.push_color(comment_color)
				label.add_text(" getter")
				label.pop() #color
				label.pop() #font
				label.pop() #cell
				method_line[prop.getter] = property_line[prop.name]
			
			label.pop() # table
			
			label.add_text("\n")
			label.add_text("\n")
			
			label.push_color(text_color)
			label.push_font(doc_font)
			label.push_indent(1)
			if prop.description.strip_edges() != "":
				add_text(prop.description)
			else:
				label.add_image(theme.get_icon("Error", "EditorIcons"))
				label.add_text(" ")
				label.push_color(comment_color)
				label.append_bbcode("There is currently no description for this property. Please help us by [color=$color][url=$url]contributing one[/url][/color]!".replace("$url", doc.contriute_url).replace("$color", link_color_text))
				label.pop()
			label.pop()
			label.pop()
			label.pop()
			label.add_text("\n")
			label.add_text("\n")
			label.add_text("\n")
	
	# Method descriptions
	if method_descr:
#		section_line.append(Pair<String, int>(TTR("Method Descriptions"), label.get_line_count() - 2))
		label.push_color(title_color)
		label.push_font(doc_title_font)
		label.add_text("Method Descriptions")
		label.pop()
		label.pop()
		label.add_text("\n")
		label.add_text("\n")
		
		for _pass in 2:
			var methods_filtered := []
			for method in methods:
				if (_pass == 0 and method.is_virtual) or (_pass == 1 and not method.is_virtual):
					methods_filtered.append(method)
			
			for i in methods_filtered.size():
				label.push_font(doc_code_font)
				add_method(methods_filtered[i], false)
				label.pop()
				
				label.add_text("\n")
				label.add_text("\n")
				
				label.push_color(text_color)
				label.push_font(doc_font)
				label.push_indent(1)
				if methods_filtered[i].description.strip_edges() != "":
					add_text(methods_filtered[i].description)
				else:
					label.add_image(theme.get_icon("Error", "EditorIcons"))
					label.add_text(" ")
					label.push_color(comment_color)
					label.append_bbcode("There is currently no description for this method. Please help us by [color=$color][url=$url]contributing one[/url][/color]!".replace("$url", doc.contriute_url).replace("$color", link_color_text))
					label.pop()
				
				label.pop()
				label.pop()
				label.pop()
				label.add_text("\n")
				label.add_text("\n")
				label.add_text("\n")
	
	return str(is_current)


func update_theme_vars() -> void:
	doc_font = theme.get_font("doc", "EditorFonts")
	doc_bold_font = theme.get_font("doc_bold", "EditorFonts")
	doc_title_font = theme.get_font("doc_title", "EditorFonts")
	doc_code_font = theme.get_font("doc_source", "EditorFonts")
	
	title_color = theme.get_color("accent_color", "Editor")
	text_color = theme.get_color("default_color", "RichTextLabel")
	headline_color = theme.get_color("headline_color", "EditorHelp")
	base_type_color = title_color.linear_interpolate(text_color, 0.5)
	comment_color = text_color * Color(1, 1, 1, 0.6)
	symbol_color = comment_color
	value_color = text_color * Color(1, 1, 1, 0.6)
	qualifier_color = text_color * Color(1, 1, 1, 0.8)
	type_color = theme.get_color("accent_color", "Editor").linear_interpolate(text_color, 0.5)


func add_type(type: String, _enum: String):
	var t := type
	if t.empty():
		t = "void"
	var can_ref := (t != "void") or not _enum.empty()
	
	if not _enum.empty():
		if _enum.split(".").size() > 1:
			t = _enum.split(".")[1]
		else:
			t = _enum.split(".")[0]
	
	var text_color := label.get_color("default_color", "RichTextLabel")
	var type_color := label.get_color("accent_color", "Editor").linear_interpolate(text_color, 0.5)
	label.push_color(type_color)
	if can_ref:
		if _enum.empty():
			label.push_meta("#" + t) #class
		else:
			label.push_meta("$" + _enum) #class
	label.add_text(t)
	if can_ref:
		label.pop()
	label.pop()


func add_method(method: MethodDocItem, overview: bool) -> void:
	method_line[method.name] = label.get_line_count() - 2 # gets overridden if description
	if overview:
		label.push_cell()
		label.push_align(RichTextLabel.ALIGN_RIGHT)
	
	add_type(method.return_type, method.return_enum)
	
	if overview:
		label.pop() #align
		label.pop() #cell
		label.push_cell()
	else:
		label.add_text(" ")
	
	if overview and method.description != "":
		label.push_meta("@method " + method.name)
	
	label.push_color(headline_color)
	add_text(method.name)
	label.pop()
	
	if overview and method.description != "":
		label.pop() #meta
	
	label.push_color(symbol_color)
	label.add_text("(")
	label.pop()
	
	for j in method.args.size():
		label.push_color(text_color)
		if j > 0:
			label.add_text(", ")
		
		add_text(method.args[j].name)
		label.add_text(": ")
		add_type(method.args[j].type, method.args[j].enumeration)
		if method.args[j].default != "":
			label.push_color(symbol_color)
			label.add_text(" = ")
			label.pop()
			label.push_color(value_color)
			add_text(method.args[j].default)
			label.pop()
		label.pop()
	
	label.push_color(symbol_color)
	label.add_text(")")
	label.pop()
	if method.is_virtual:
		label.push_color(qualifier_color)
		label.add_text(" ")
		add_text("virtual")
		label.pop()
	
	if overview:
		label.pop() #cell


func add_text(bbcode: String) -> void:
	var base_path: String
	
	var doc_font := label.get_font("doc", "EditorFonts")
	var doc_bold_font := label.get_font("doc_bold", "EditorFonts")
	var doc_code_font := label.get_font("doc_source", "EditorFonts")
	var doc_kbd_font := label.get_font("doc_keyboard", "EditorFonts")
	
	var headline_color := label.get_color("headline_color", "EditorHelp")
	var accent_color := label.get_color("accent_color", "Editor")
	var property_color := label.get_color("property_color", "Editor")
	var link_color := accent_color.linear_interpolate(headline_color, 0.8)
	var code_color := accent_color.linear_interpolate(headline_color, 0.6)
	var kbd_color := accent_color.linear_interpolate(property_color, 0.6)
	
	bbcode = bbcode.dedent().replace("\t", "").replace("\r", "").strip_edges()
	
	bbcode = bbcode.replace("[csharp]", "[b]C#:[/b]\n[codeblock]")
	bbcode = bbcode.replace("[gdscript]", "[b]GDScript:[/b]\n[codeblock]")
	bbcode = bbcode.replace("[/csharp]", "[/codeblock]")
	bbcode = bbcode.replace("[/gdscript]", "[/codeblock]")
	
	# Remove codeblocks (they would be printed otherwise)
	bbcode = bbcode.replace("[codeblocks]\n", "")
	bbcode = bbcode.replace("\n[/codeblocks]", "")
	bbcode = bbcode.replace("[codeblocks]", "")
	bbcode = bbcode.replace("[/codeblocks]", "")
	
	# remove extra new lines around code blocks
	bbcode = bbcode.replace("[codeblock]\n", "[codeblock]")
	bbcode = bbcode.replace("\n[/codeblock]", "[/codeblock]")
	
	var tag_stack := []
	var code_tag := false

	var pos := 0
	while pos < bbcode.length():
		var brk_pos := bbcode.find("[", pos)
		if brk_pos < 0:
			brk_pos = bbcode.length()
		
		if brk_pos > pos:
			var text := bbcode.substr(pos, brk_pos - pos)
#			if not code_tag:
#				text = text.replace("\n", "\n\n")
			label.add_text(text)
		
		if brk_pos == bbcode.length():
			break #nothing else to add
		
		var brk_end := bbcode.find("]", brk_pos + 1)
		
		if brk_end == -1:
			var text := bbcode.substr(brk_pos, bbcode.length() - brk_pos)
			if not code_tag:
				text = text.replace("\n", "\n\n")
			label.add_text(text)
			break
		
		var tag := bbcode.substr(brk_pos + 1, brk_end - brk_pos - 1)
		
		if tag.begins_with("/"):
			var tag_ok = tag_stack.size() and tag_stack[0] == tag.substr(1, tag.length())
			if not tag_ok:
				label.add_text("[")
				pos = brk_pos + 1
				continue
			
			tag_stack.pop_front()
			pos = brk_end + 1
			if tag != "/img":
				label.pop()
				if code_tag:
					label.pop()
			code_tag = false
		
		elif code_tag:
			label.add_text("[")
			pos = brk_pos + 1
		
		elif tag.begins_with("method ") || tag.begins_with("member ") || tag.begins_with("signal ") || tag.begins_with("enum ") || tag.begins_with("constant "):
			var tag_end := tag.find(" ")
			var link_tag := tag.substr(0, tag_end)
			var link_target := tag.substr(tag_end + 1, tag.length()).lstrip(" ")
			
			label.push_color(link_color)
			label.push_meta("@" + link_tag + " " + link_target)
			label.add_text(link_target + ("()" if tag.begins_with("method ") else ""))
			label.pop()
			label.pop()
			pos = brk_end + 1
		
		elif class_list.has(tag):
			label.push_color(link_color)
			label.push_meta("#" + tag)
			label.add_text(tag)
			label.pop()
			label.pop()
			pos = brk_end + 1
		
		elif tag == "b":
			#use bold font
			label.push_font(doc_bold_font)
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "i":
			#use italics font
			label.push_color(headline_color)
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "code" || tag == "codeblock":
			#use monospace font
			label.push_font(doc_code_font)
			label.push_color(code_color)
			code_tag = true
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "kbd":
			#use keyboard font with custom color
			label.push_font(doc_kbd_font)
			label.push_color(kbd_color)
			code_tag = true # though not strictly a code tag, logic is similar
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "center":
			#align to center
			label.push_paragraph(RichTextLabel.ALIGN_CENTER, Control.TEXT_DIRECTION_AUTO, "")
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "br":
			#force a line break
			label.add_newline()
			pos = brk_end + 1
		elif tag == "u":
			#use underline
			label.push_underline()
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "s":
			#use strikethrough
			label.push_strikethrough()
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag == "url":
			var end := bbcode.find("[", brk_end)
			if end == -1:
				end = bbcode.length()
			var url = bbcode.substr(brk_end + 1, end - brk_end - 1)
			label.push_meta(url)
			
			pos = brk_end + 1
			tag_stack.push_front(tag)
		elif tag.begins_with("url="):
			var url := tag.substr(4, tag.length())
			label.push_meta(url)
			pos = brk_end + 1
			tag_stack.push_front("url")
		elif tag == "img":
			var end := bbcode.find("[", brk_end)
			if end == -1:
				end = bbcode.length()
			var image := bbcode.substr(brk_end + 1, end - brk_end - 1)
			var texture := load(base_path.plus_file(image)) as Texture
			if texture:
				label.add_image(texture)
			
			pos = end
			tag_stack.push_front(tag)
		elif tag.begins_with("color="):
			var col := tag.substr(6, tag.length())
			var color := Color(col)
			label.push_color(color)
			pos = brk_end + 1
			tag_stack.push_front("color")
		
		elif tag.begins_with("font="):
			var fnt := tag.substr(5, tag.length())
			var font := load(base_path.plus_file(fnt)) as Font
			if font.is_valid():
				label.push_font(font)
			else:
				label.push_font(doc_font)
			
			pos = brk_end + 1
			tag_stack.push_front("font")
		
		else:
			label.add_text("[") #ignore
			pos = brk_pos + 1


func sort_methods(a: Dictionary, b: Dictionary) -> bool:
	return a.name < b.name

