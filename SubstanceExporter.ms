/*  
[INFO] 

NAME = Substance Exporter
VERSION = 1.2.4
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Astics Aivis
SKYPE = Astics Aivis
HELP = 
WEB=https://3dground.net

[INSTALL]

MACRO=SubstanceExporter
CAT=3DGROUND
TEXT=Substance Exporter
ICON=#("PhysX_Main", 30)

[1.0.0]

* First release =

[1.0.1]

+ Added: Auto render UVW=

[1.1.0]

-BugFix: Materials count in statistic=
- BugFix: Fatal error when pressed button Triangles=
+ Added: Batch render UVW=
* Changed: Small fixes=

[1.1.1]

-BugFix: Small fixes=

[1.2.0]

* Changed: Fully changed select/get NGons, Edges >5 and Triangles=

[1.2.1]

* Changed: Apply Edit_Poly modifier when select  NGons, Edges >5 and Triangles=

[1.2.2]

- BugFix: Small bug fixes=

[1.2.3]

* Changed: Delete Edit_Poly modifeirs if not found issues for  NGons, Edges >5 and Triangles=

[1.2.4]

- BugFix: Small bug fixes=

[ABOUT]

Quick export and check models for Substance Painter =

[TEST]

[SCRIPT]
*/	

try(closeRolloutFloater rSubstanceExporter)catch()
global rSubstanceExporter = newRolloutFloater "Substance Exporter" 260 560

global _MAIN_SUBSTANCE_STEP1
global BitmapTypes = #(Bitmaptexture, CoronaBitmap)

fn trim s c: " " = trimRight (trimLeft s c) c
fn explode s tag: ";" = (
	a = filterString s tag
	return for i in a collect trim i
)
fn implode a tag: ";" = 
(
	s = ""
	for i in a do s += i as string + tag
	return trimRight s tag
)


struct scriptInfo (
	ini = getThisScriptFilename(),
	fn implode a tag: "\n"= (
		s = ""
		for i in 1 to a.count do s += a[i] + (if(i != a.count) then tag else "")			
		return s
	),
	web = getINISetting ini "INFO" "WEB",
	version = getINISetting ini "INFO" "VERSION",
	author = getINISetting ini "INFO" "AUTHOR",
	name = getINISetting ini "INFO" "NAME",
	overview = implode (getINISetting ini "ABOUT"),
	dev = getINISetting ini "INFO" "DEV",
	help = getINISetting ini "INFO" "HELP",
	fn release num = (
		return implode (getINISetting ini num)
	),
	fn releases = (
		for i in (getINISetting ini) where matchPattern i pattern: "*.*.*"  collect i
	)
)

fn showTooltip c t =
(
	toolTip = dotnetobject "System.Windows.Forms.ToolTip"
	toolTip.SetToolTip c t   
	--toolTip.Active = true    
	toolTip.isBalloon = true
	toolTip.InitialDelay = 100
	toolTip.AutoPopDelay = 500
	toolTip.ReshowDelay = 50
	toolTip.ToolTipTitle = "Warning!"
	toolTip.Show t c 3000	
	toolTip.ToolTipIcon = (dotnetclass "System.Windows.Forms.ToolTipIcon").Warning
)

fn writeFile f s =
(
	f = openFile f mode: "wt"

	format(s as string) to:f

	flush f
	close f
)

fn stripTab m = 
(
	q = filterString m "\t"	
	l = ""
	for i in q do l += i
	
	return l
)

fn showStatistic m title:"Statistic" width: 320 =
(
	global rStatistic
	try(DestroyDialog rStatistic)catch()	
	global szStat = m
	global iWidth = width
	
	rollout rStatistic title
	(
		edittext edtStat "" height: 280 width: iWidth offset: [-15, -2] readOnly: true
		button btnSave "Save" align: #left width: 50 across: 2
		button btnOK "Ok" align: #right  width: 35
		
		on btnOK pressed do try(DestroyDialog rStatistic)catch()
		on rStatistic open do edtStat.text = szStat	
		on btnSave pressed do (
			f = getSaveFileName  caption: "Save File" types: "Text Documents (*.txt)|*.txt|"
			if(f == undefined) do return false
			
			t = stripTab edtStat.text
			
			writeFile f t
		)
		
	)

	createDialog rStatistic width 315 modal: false
)

fn stripName n = (
	nn = filterString n "_"
	if(nn.count ==  0) do return undefined
	if(nn.count == 1) do return nn[1]
	
	s = ""
	for i in 1 to nn.count - 1 do (
		s += nn[i]
		if(i != (nn.count - 1)) do s += "_"
	)
	
	return s
)

fn useSettings k v type:#get =
(
	f = getThisScriptFilename() + ".ini"
	case type of
	(
		#set: setIniSetting f "SETTINGS" k v
		default: getIniSetting f "SETTINGS" k
	)
)

fn boost = if (((maxVersion())[1] / 1000) >= 13) do windows.processPostedMessages() 

fn freezeUi =
(
  	source = ""
  	source += "using System;\n"
  	source += "using System.Runtime.InteropServices;\n"
  	source += "class WindowsGhosting\n"
  	source += "{\n"
  	source += " [DllImport(\"user32.dll\")]\n"
  	source += " public static extern void DisableProcessWindowsGhosting();\n"
  	source += "}\n"
  
  	csharpProvider = dotnetobject "Microsoft.CSharp.CSharpCodeProvider"
  	compilerParams = dotnetobject "System.CodeDom.Compiler.CompilerParameters"
  
  	compilerParams.GenerateInMemory = on
  	compilerResults = csharpProvider.CompileAssemblyFromSource compilerParams #(source)
  
  	assembly = compilerResults.CompiledAssembly
  	windowsGhosting = assembly.CreateInstance "WindowsGhosting"
  	windowsGhosting.DisableProcessWindowsGhosting()
)

fn quickAttach objs name: undefined = (
	
	freezeUi()		
	clearSelection()
	cnt = 0
	
	tmp = #()
	chunk = 300
	
	t = Editable_Mesh()	
	convertTo t Editable_Poly
	t.name = objs[1].name
	if(name != undefined) do t.name = name
	
	append tmp t
			
	progressStart "Quick Attach"
	
	for i in 1 to objs.count do (
		cnt += 1
		
		if(cnt >= chunk) do (
			cnt = 1
			t = Editable_Mesh()
			convertTo t Editable_Poly
			t.name = objs[i].name
			append tmp t
			gc()
			boost()
		)
		
		if(not (isDeleted objs[i])  and (SuperClassOf objs[i] == GeometryClass) and (isValidNode objs[i])) do (
			polyop.attach  t objs[i] 
			
			boost()
			if (keyboard.EscPressed) do (
				q = queryBox "Do you want to stop Quick Attach?" title: "Confirm"
				progressEnd()
				if(q) do return t
			)
		) 
		
		progressUpdate (100 * i / objs.count)
	)
	
	progressEnd()
	
	progressStart "Quick Attach"
		
	if(tmp.count != 0) do (
		t = Editable_Mesh()	
		convertTo t Editable_Poly
		t.name = tmp[1].name
		
		for i in 1 to tmp.count do (
			polyop.attach  t tmp[i] 				
			progressUpdate (100 * i / tmp.count)
		)
		
		gc()
	)
	
	progressEnd()
		
	select t
	t.pivot = t.center
	free tmp
	free objs
			
	return t
)

fn isSelected exact: undefined =
(
	ss = selection.count < 1
	if(exact != undefined) do ss = selection.count != exact
	
	if(ss and exact == undefined) do 
	(
		messageBox "Please select model!" title: "Warning!"
		return false
	)
	
	if(ss and exact != undefined) do 
	(
		messageBox "Please select one model!" title: "Warning!"
		return false
	)
	
	return true
)

fn isSelectedEditPoly exact: undefined =
(
	ss = selection.count < 1
	if(exact != undefined) do ss = selection.count != exact
	
	if(ss and exact == undefined) do 
	(
		messageBox "Please select model!" title: "Warning!"
		return false
	)
	
	if(ss and exact != undefined) do 
	(
		messageBox "Please select one model!" title: "Warning!"
		return false
	)
	
	nonPoly = for i in selection where classOf i.baseObject != Editable_Poly collect i
	
	if(nonPoly.count > 0) do (
		messageBox "Please select only Editable Poly objects!" title: "Warning!"
		return false
	)
	
	return true
)

rollout _MAIN_SUBSTANCE_STEP1 "Main"
(
	group "1. Info" (
		button btnStatistic "Statistic" align: #left across: 2 width: 107 height: 23
		button btnRenderUVW "Render UVW" align: #right width: 107 height: 23
	)
	
	group "2. Find" (
		button btnFindTriangles "Triangles" across: 3 align: #left width: 70 height: 23
		button btnFindNgons "Ngons" align: #center width: 70 height: 23
		button btnFindEdges5 "Edges >5" align: #right width: 70 height: 23
		button btnFindObjectsByMat "Objects by Mat" across: 2 align: #left width: 107 height: 23
		button btnFindOverlappedUVW "Overlapped UVW" align: #right width: 107 height: 23
	)
	
	group "3. Geometry Fix" (
		button btnFixEmptyObjects "Empty Objs" across: 3 align: #left width: 70 height: 23
		button btnFixBoxTrick "Box Trick" align: #center width: 70 height: 23
		button btnFixResetXForm "Reset XForm" align: #right width: 70 height: 23
	)
	
	group "4. Group" (
		button btnMakeGroup "Make Group" across: 3 align: #left width: 85 height: 23
		label lblOr1 "or" align: #center offset: [0, 4]
		button btnAttachSelected "Attach Selected" align: #right width: 85 height: 23
	)
	
	group "5. Set Pivot" (
		button btnSetPivotBottom "Bottom" across: 3 align: #left width: 85 height: 23
		label lblOr2 "or" align: #center offset: [0, 4]
		button btnSetPivotTop "Top" align: #right width: 85 height: 23
	)
	
	group "6. Positon" (
		button btnPositionCenter "Position in Center Scene" height: 23 align: #center
	)
		
	group "Export Selected" (
		button btnExportOBJ "OBJ" across: 4 height: 23 align: #left width: 38 
		button btnExportFBX "FBX" height: 23 align: #left offset: [-12, 0] width: 38 
		button btnExport3DS "3DS" height: 23 align: #left offset: [-24, 0] width: 38 
		button btnExportAll "OBJ+FBX+3DS" height: 23 align: #right
	)
	
	group "info.txt" (
		checkbox cbxInfoDimMM "Dimension in mm" checked: true
		checkbox cbxInfoDimCM "Dimension in cm" checked: true
		checkbox cbxInfoDimM "Dimension in m" checked: true
		checkbox cbxInfoDimInch "Dimension in inch" checked: true
	)
	
	timer tmrBoxTrick "" interval:100 active:false
	
	global nullArray = #{}
	
	on _MAIN_SUBSTANCE_STEP1 open do (
		freezeUi()
	)
	
	fn msgDone = messageBox "Done!" title: "Done!" beep: false
	fn msgNotFund = messageBox "Not found!" title: "Success!" beep: false
		
	fn addEditPoly name lvl type = (	
		--addModifier $ (Edit_Poly name: name); $.modifiers[name].setSelection type #{} ; subObjectLevel = lvl; $.modifiers[name].select type sel				
		addModifier $ (Edit_Poly name: name)
		subObjectLevel = lvl
		$.modifiers[name].setSelection type #{}
	)
	
	fn getEditPolySel name lvl type = (
		subObjectLevel = lvl
		$.modifiers[name].GetSelection type
	)
	
	fn delMod name = (
		deleteModifier $  $.modifiers[name]
	)
		
	fn getEmptyGroups = for o in helpers where isGroupHead o and o.children.count == 0 and not isDeleted o collect o
	fn getEmptyObjects = for o in geometry where try((getNumFaces o) == 0)catch(false) collect o
	
	fn removeEmptyObjects = (
		eg = getEmptyGroups()
		eo = getEmptyObjects()
		
		for o in eg where not isDeleted o do try(delete o)catch()	
		for o in eo where not isDeleted o do try(delete o)catch()

		m = "Deleted " + (eg.count + eo.count) as string + " empty objects!"
		messageBox m title: "Done!"
	)
	
	fn numberSpaces str num: 3= (
		r = ""
		ii = 1
		
		for i in str.count to 1 by -1 do
		(
			space = ""					
			if (ii == num) do (
				space = " "
				ii = 0
			)			
			ii += 1			
			r = space + str[i] + r
		)
		
		return (trimLeft r " ")
	)
	
	/* ------------------------------------------- */
	
	fn findTriangles o d: false = 
	(	
		n = "Triangles"
		t = #Face	
		max modify mode 
		addEditPoly n 4 t	
		PolyToolsSelect.NumericFace 3 1 false
		v = getEditPolySel n 4 t
		if(d or v.numberset == 0) do delMod n 	
		return v.numberset
	)
	
	fn findNGons o d:false = 
	(	
		n = "Ngons"
		t = #Face	
		max modify mode 
		addEditPoly n 4 t
		PolyToolsSelect.NumericFace 5 3 false		
		v = getEditPolySel n 4 t
		if(d or v.numberset == 0) do delMod n 	
		return v.numberset	
	)
	
	fn findQuads o d: false = 
	(	
		n = "Quads"
		t = #Face	
		max modify mode 
		addEditPoly n 4 t
		PolyToolsSelect.NumericFace 4 1 false		
		v = getEditPolySel n 1 t
		if(d or v.numberset == 0) do delMod n 	
		return v.numberset	
	)
	
	fn findEdges5 o d: false= (		
		n = "Edges >5"
		t = #Vertex	
		max modify mode 
		addEditPoly n 1 t	
		PolyToolsSelect.NumericVertex 5 3 false			
		v = getEditPolySel n 1 t			
		if(d or v.numberset == 0) do delMod n 	
		return v.numberset
	)
	
	/* ------------------------------------------- */
	
	/*
	fn selXFaces objs num: 3 = (
		max modify mode 
		sel = 0
		for o in objs where classOf o.baseObject == Editable_Poly do (
			if(canConvertTo o Editable_Poly) do convertToPoly o
			o = o.baseObject
			faces = #{1..(polyOp.getNumFaces o)}
			ss = #{}
			for f in faces do (
				t = (polyOp.getVertsUsingFace o f).numberset
				if(t == 0) do continue
				if(t > 4) do t = 5
				if(t == num) do append ss f
							
				polyOp.setFaceSelection o ss
				sel += ss.numberset				
			)
			boost()
		)
		modPanel.addModToSelection (Edit_Poly ()) ui:on
		try(if subObjectLevel != 4 do subObjectLevel = 4) catch()
		max views redraw
		return sel
	)
	
	fn selXVertices objs num: 3 = (
		max modify mode 
		sel = 0
		for o in objs where classOf o.baseObject == Editable_Poly do (
			--if(canConvertTo o Editable_Poly) do convertToPoly o
			o = o.baseObject
			verts = #{1..(polyOp.getNumVerts o)}
			ss = #{}
			for v in verts do (
				t = (polyOp.getEdgesUsingVert o v).numberset				
				if(t == 0) do continue
				if(t > 5) do t = 6
				if(t == num) do append ss v
							
				polyOp.setVertSelection o ss
				sel += ss.numberset
			)
			boost()
		)
		modPanel.addModToSelection (Edit_Poly ()) ui:on
		try(if subObjectLevel != 1 do subObjectLevel = 1)catch()
		max views redraw
		return sel
	)
	
	fn vertXCount objs num: 3 = (
		iVerts = 0
		for o in objs where classOf o.baseObject == Editable_Poly do (
			o = o.baseObject
			verts = #{1..(polyOp.getNumVerts o)}
			
			for v in verts do (
				t = (polyOp.getEdgesUsingVert o v).numberset
				if(t == 0) do continue
				if(t > 5) do t = 6
				if(t == num) do iVerts += 1			
			)
			boost()
		)
		sVerts = iVerts as string
		return numberSpaces sVerts
	)
	
	fn polyXCount objs num: 3 = (
		iFaces = 0
		for o in objs where classOf o.baseObject == Editable_Poly do (
			o = o.baseObject
			faces = #{1..(polyOp.getNumFaces o)}
			
			for f in faces do (
				t = (polyOp.getVertsUsingFace o f).numberset
				if(t == 0) do continue
				if(t > 4) do t = 5
				if(t == num) do iFaces += 1			
			)
			boost()
		)
		sFaces = iFaces as string
		return numberSpaces sFaces
	)*/
		
	fn getUnits = (
		u = (trimLeft (units.SystemType as string) "#")
		u[1] = toUpper u[1]
		return u
	)
		
	fn polyCount s =
	(	
		iPoly = 0		
		a = for i in s where superClassOf i == GeometryClass collect (getPolygonCount i)[1]
		for i in a do iPoly += i						
			
		sPoly = iPoly as string		
		return numberSpaces sPoly
	)
	
	fn vertCount s = (
		iVert = 0
		a = for i in s where superClassOf i == GeometryClass collect (getNumVerts i.baseObject.mesh)
		for i in a do iVert += i
		sVert = iVert as string		
		return numberSpaces sVert	
	)
	
	fn triCount s = (
		iTri = 0
		a = for i in s where superClassOf i == GeometryClass collect (GetTriMeshFaceCount i)[1]
		for i in a do iTri += i
		sTri = iTri as string		
		return numberSpaces sTri	
	)
	
	fn trim_null n f: false = (
		a = filterString n "."
		if(a.count < 2) do return n
		if(f) do (
			a[2] = trimLeft a[2] "0123456789"
			return  a[1] + a[2]
		)
			
		if((trimRight a[2] "'\"cm") == "0") do (
			a[2] = trimLeft a[2] "0"
			return  a[1] + a[2]
		)
		
		return a[1] + "." + a[2]
	)
	
	fn getDim s type: "m"=
	(
		t1 = units.DisplayType
		t2 = units.SystemType
		t3 = units.USType
		t4 = units.MetricType
		
		case type of (
			"mm": (
				units.DisplayType = #Metric
				units.MetricType = #Millimeters
			)
			"cm": (
				units.DisplayType = #Metric
				units.MetricType = #Centimeters
			)
			"m": (
				units.DisplayType = #Metric
				units.MetricType = #Meters
			)
			"inches": (
				units.DisplayType = #US
				units.USType = #Dec_In
			)
		)
		
		d = s.max - s.min
		
		d = for i in 1 to 3 collect ((d[i] * 100) as integer / 100.0 )
		
		d[1] = units.formatValue d[1] 
		d[2] = units.formatValue d[2]
		d[3] = units.formatValue d[3] 
		
		for i in 1 to 3 do (
			case type of (
				"mm":  d[i] = trim_null d[i] f: true					
				default: d[i] = trim_null d[i] f: false
			)
		)
		
		units.DisplayType = t1 
		units.MetricType = t2
		units.USType = t3
		units.MetricType = t4
			
		return d[1] + " x " + d[2] + " x " + d[3]
	)
		
	
	fn materialCount sel = (
		materials = #()
		for i in sel where i.material != undefined do (
			m = i.material
			if(classOf m == MultiMaterial) then (
				for ii in m where ii != undefined do append materials m
				continue
			)
			
			append materials m
		)
		
		materials = makeUniqueArray materials
		
		sMat = materials.count as string
		return sMat 
	)
	
	fn getStatistic sel: selection displ: true = (
		
		sel = sel as array
		
		bBoxTrick = "Yes"
		bResetXForm = "Yes"
		
		for i in sel where getUserProp i "boxtrick" == undefined do bBoxTrick = "No"
		for i in sel where getUserProp i "xform" == undefined do bResetXForm = "No"
		clearSelection()
		
		iTriangles = 0
		iNgons = 0
		iEdges5 = 0
		iQuads = 0
		
		disableSceneRedraw()
		for i in sel do (
			select i
			/*polyop.setFaceSelection $ #{}
			polyop.setVertSelection  $ #{}
			polyop.setEdgeSelection   $ #{}*/
			iTriangles += findTriangles $ d: true
			iNgons += findNGons $ d: true
			iEdges5 += findEdges5 $ d: true
			iQuads += findQuads $	d: true

			/*polyop.setFaceSelection $ #{}
			polyop.setVertSelection  $ #{}
			polyop.setEdgeSelection   $ #{}*/
		)
		try(subObjectLevel = 0) catch()
		try(select sel) catch()
		
		enableSceneRedraw()
		enableSceneRedraw()
		enableSceneRedraw()
				
		n = "\n"
		o = "Geometry:" + n 
		o += "Units: " + getUnits() + n
		o += "Polygons: " + (polyCount sel) + n
		o += "Vertex: " + (vertCount sel) + n
		o += "Triangles: " + (iTriangles as string) + n
		o += "Quads: " + (iQuads as string) + n
		o += "Ngons: " + (iNgons as string) + n
		o += "Vertex with more than 5 edges: " + (iEdges5 as string) + n + n
		o += "Object:" + n 
		if(cbxInfoDimMM.checked) do o += "Dimenson mm: " + getDim $ type: "mm" + n
		if(cbxInfoDimCM.checked) do o += "Dimenson cm: " + getDim $ type: "cm" + n
		if(cbxInfoDimM.checked) do o += "Dimenson m: " + getDim $ type: "m" + n
		if(cbxInfoDimInch.checked) do o += "Dimenson inches: " + getDim $ type: "inches" + n
		o += "Model parts: " + (selection.count as string) + n
		o += "Material count: " + (materialCount sel) + n
		o += "XForm: " + bResetXForm + n
		o += "BoxTrick: " + bBoxTrick + n
		
		return o
	)
	
	fn selectOverlappedUVW o = (
		if(canConvertTo o Editable_Poly) do convertToPoly o
		try(polyop.setFaceSelection o #{}) catch()
		u = UVWunwrap()
		addModifier o u
		try(if subObjectLevel != 3 do subObjectLevel = 3)catch()
		actionMan.executeAction 2077580866 "40183"	
	)
	
	fn renderUVW filename: "" = (
		
		--if(canConvertTo o Editable_Poly) do convertToPoly o
		
		u = UVWunwrap()
		
		--modPanel.addModToSelection (Edit_Poly()) ui:off
		modPanel.addModToSelection u ui:on
					
		u.renderuv_width = 2048
		u.renderuv_height = 2048
		u.renderuv_fillColor = color 186 186 186
		u.renderuv_fillalpha = 1.0
		u.renderuv_fillmode = 1
		u.renderuv_showoverlap = true
		u.renderuv_edgeColor = color 255 255 255
		u.renderuv_edgealpha = 1.0
		u.renderuv_visibleedges = true
		u.renderuv_invisibleedges = false
		u.renderuv_seamedges = true
		renderuv_showframebuffer = true
	
		u.renderUV filename
		
		try(for i in selection do deleteModifier i 1) catch()
	)
	
	fn selectObjectsByMat o = (
		m = o.material 
		if(o.material == undefined) do return messageBox "Selected object has no material!" title: "Warning!"
		
		objs = for i in objects where i.material == m collect i
			
		clearSelection()
		try(select objs) catch()
	)

	fn ungroupRecursive s = for i in s where isGroupHead i and isValidNode i do explodeGroup i
	
	fn makeGroup = (				
		ungroupRecursive selection
			
		group selection name: (uniqueName "Group_") select:true				
	)
	
	fn setPivot p: #bottom =
	(	
		pm = MaxOps.pivotMode 
		MaxOps.pivotMode = #pivotOnly
	
		for i in selection as array do 
		(	
			i.pivot = selection.center			
			pivotPoint = case p of
			(
				#bottom: i.pivot.z = selection.min.z
				#top: i.pivot.z = selection.max.z
			)					 
		)

		max views redraw			
			
		MaxOps.pivotMode = pm
		max views redraw
		
	)
	
	fn setPivotPoint p: #bottom =
	(
		if(not isSelected()) do return false
		
		setPivot p: p
	)
	
	fn setToCenterScene = (
		g = group selection

		g.pos = [0,0,0]
		g.pos.z = 0 - selection.min.z
			
		ungroup g		
	)
	
	fn fixResetXForm = (
		undo on
		(	
			hObj = for i in selection where superClassOf i == GeometryClass collect i
			
			btnFixResetXForm.enabled = false
			
			progressStart "Reset XForm..."
			escapeEnable
					
			for i in 1 to hObj.count do
			(			
				ResetXForm hObj[i]
				if(canConvertTo hObj[i] Editable_Poly) do 
				(
					collapseStack hObj[i]
					convertToPoly hObj[i]
				)
					
				setUserProp hObj[i] "xform" true				
				
				progressUpdate (100.0 * i / hObj.count)	
							
				if(getProgressCancel() == true) do exit	
			)	

			btnFixResetXForm.enabled = true
			progressEnd()	
		)
	)
	
	fn exportSelected types: #("obj") = (		
		if(not isSelectedEditPoly()) do return false
		
		t = implode types tag: "+"
		
		f = getSaveFileName caption: "Export Selected" types: ((toUpper t) + " (*." + t + ")|*." + t)
		if(f == undefined) do return false
		
		p = getFileNamePath f
		n = getFileNameFile f
			
		for t in types do (
			exportFile (p + n + "." + t) #noPrompt selectedOnly:true
		)
		
		s = getStatistic()
		writeFile (p + "_" + n + ".txt") s
		
		shellLaunch p ""
	)
	
	on btnExportOBJ pressed do exportSelected types: #("obj")
	on btnExportFBX pressed do exportSelected types: #("fbx")
	on btnExport3DS pressed do exportSelected types: #("3ds")
	on btnExportAll pressed do exportSelected types: #("obj", "fbx", "3ds")
	
	on tmrBoxTrick tick do
	(		
		clearListener()
		progressStart "Box Trick..."
		escapeEnable
		
		undo on
		(
			hObj = selection as array
					
			forSelect = #()
			
			for i = 1 to hObj.count where not isDeleted hObj[i] and superClassOf hObj[i] == GeometryClass do
			(														
				--g = getObjectHead hObj[i]
				
				convertToMesh hObj[i]
				convertToPoly hObj[i]	
				
				b = convertToPoly(box())				
				b.rotation = hObj[i].rotation
				b.name = hObj[i].name
				b.pos = hObj[i].pos
				b.wirecolor = hObj[i].wirecolor
				setUserPropBuffer b (getUserPropBuffer hObj[i])
						
				b.EditablePoly.SetSelection #Face #{1..6}
				b.EditablePoly.delete #Face		
				
				polyop.attach b hObj[i]		
								
				progressUpdate (100.0 * i / hObj.count)	
							
				if(getProgressCancel() == true) do exit	
					
				append forSelect b
				setUserProp b "boxtrick" true				
			)
					
			btnFixBoxTrick.enabled = true
			tmrBoxTrick.active = false
			
			try(select forSelect)catch()
		)
				
		
		progressEnd()
	)
	
	on btnFindTriangles pressed do (
		if(not isSelectedEditPoly exact: 1) do return false
		
		c = findTriangles $
		if(c == 0) do msgNotFund()	
	)
			
	on btnFindNgons pressed do (
		if(not isSelectedEditPoly()) do return false
		
		c= findNGons $
			
		if(c == 0) do msgNotFund()	
	)
	
	on btnFindEdges5 pressed do (
		if(not isSelectedEditPoly exact: 1) do return false
		
		c = findEdges5 $
		if(c == 0) do msgNotFund()
	)
	
	on btnStatistic pressed do (
		if(not isSelectedEditPoly()) do return false
		
		m = getStatistic()
		showStatistic m 
	)
	
	on btnFindOverlappedUVW pressed do (
		if(not isSelectedEditPoly exact: 1) do return false
		
		objs = selection as array
			
		for o in objs do selectOverlappedUVW o
	)
	
	on btnFindObjectsByMat pressed do (
		if(not isSelected exact: 1) do return false
			
		o = selection[1]
			
		selectObjectsByMat o
	)
	
	on btnRenderUVW pressed do (
		if(not isSelectedEditPoly()) do return false
					
		f = getSaveFileName caption: "Save UVW Render" types:"JPG(*.jpg)|*.jpg|PNG(*.png)|*.png" filename: "uvw"
		if(f == undefined) do return false	
			
		p = getFileNamePath f
		ext = getFilenameType f
		n = getFilenameFile  f
		sel = selection as array
							
		--filename = --p + o.name+ "_" + n + ext	
		
		renderUVW filename: f				
	)
	
	on btnMakeGroup pressed do (
		if(not isSelected()) do return false
			
		makeGroup()
	)
	
	on btnAttachSelected pressed do (
		if(not isSelected()) do return false
		
		objs = selection as array
			
		quickAttach objs
	)
	
	on btnSetPivotBottom pressed do setPivotPoint p: #bottom
	on btnSetPivotTop pressed do setPivotPoint p: #top
		
	on btnPositionCenter pressed do (
		if(not isSelected()) do return false	

		setToCenterScene()
	)
	
	on btnFixBoxTrick pressed do (
		if(not isSelected()) do return false
			
		ungroupRecursive selection
			
		tmrBoxTrick.active = true
		btnFixBoxTrick.enabled = false
	)
	
	on btnFixResetXForm pressed do (
		if(not isSelected()) do return false
			
		fixResetXForm()
	)
	
	on btnFixEmptyObjects pressed do (
		removeEmptyObjects()
	)
)

rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	local c = color 200 200 200 
	hyperLink href1 "" address: "" align: #center hoverColor: c visitedColor: c offset: [0, 20]
	
	on _rAbout open do
	(				
		i = scriptInfo()
			
		lblName.caption = i.name
		lblAuthor.caption = i.author
		lblVer.caption = i.version
		lblCopy.caption = i.dev
		href1.address = i.web
		href1.caption = i.web								
	)
)

addRollout _MAIN_SUBSTANCE_STEP1 rSubstanceExporter border: true
addRollout _rAbout rSubstanceExporter rolledUp:true