#SingleInstance off
#MaxHotkeysPerInterval 200
#NoTrayIcon
SetBatchLines, -1
SetWinDelay, -1
SetControlDelay, -1
CoordMode, ToolTip, Screen
Menu, Tray, Icon
DetectHiddenWindows on
WinClose % "ahk_id" OtherInstance()
DetectHiddenWindows, Off

global AppName := "Columbus"
global AppVersion := 0.36
global AppDirectory := A_ScriptDir "\data"

if %1%
	LaunchParam()
	
global Settings := new Settings()

Menu, Tray, NoStandard
Menu, Tray, Add, Show Columbus, MenuHandler
Menu, Tray, Add
Menu, Tray, Add, Settings, MenuHandler
Menu, Tray, Add, Manager, MenuHandler
Menu, Tray, Add
Menu, Tray, Add, Reset GUI position, MenuHandler
Menu, Tray, Add
if FileExist(A_ScriptDir "\ico.ico")
	Menu, Tray, Icon, % A_ScriptDir "\ico.ico"
if (Settings.Debug) { ; only supposed to happen if it's running on my pc lol
	Menu, Tray, Add, Variables, ListVars
	Menu, Tray, Add
} Menu, Tray, Add, Exit, Exit
Menu, Tray, Click, 2
Menu, Tray, Default, Show Columbus

OnMessage(0x201, "WM_LBUTTONDOWN")

print("Starting up..")

if (!FileExist(AppDirectory)) {
	FileCreateDir % AppDirectory
	TrayTip, % AppName, CTRL+ALT+P to start!
}

if (!FileExist(AppDirectory "\settings.ini"))
	Settings.Defaults()

Settings.Read()

; --- delete remains of old version "FuzzyComp", do not remove :3
if (FileExist(A_Appdata "\FuzzyComp\")) {
	RegDelete, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run, FuzzyComp ; delete the old entry for launch on startup
	FileDelete % A_Appdata "\FuzzyComp\"
} if (FileExist(A_ScriptDir "\FuzzyComp.exe"))
	FileDelete % A_ScriptDir "\FuzzyComp.exe"
; --- delete old version (we just updated)
if (FileExist(AppDirectory "\old")) {
	TrayTip, % AppName, Successfully updated to v%AppVersion%
	FileDelete % Appdirectory "\old"
}

SetWorkingDir % AppDirectory

if (Settings.UpdateCheck) && (DllCall("wininet\InternetGetConnectedState", "Uint", 0))
	CheckForUpdates(false)

print("Parsing the registry..")
ItemHandler := new ItemHandler()
ItemHandler.Search()
ItemHandler.Verify("items.ini")
ItemHandler.Verify("deleted_items.ini")

global hwndGui, ImageList, 1

Gui Font, s13 cWhite Q1, Candara
Gui Color, 383838, 383838
Gui Margin, 0, 0

Gui Add, ListView, % "w" Settings.Width " h" Settings.Height - 25 " vMyListView gListAction Count50 -Grid -LV0x10 +LV0x20 -E0x200 +LV0x100 -TabStop -Hdr -Multi +AltSubmit ", Result|Rating|Contains|Abbreviation|Beginning|spacer
global ImageList := IL_Create(10)
LV_SetImageList(ImageList)

ItemRefresh()

LV_ModifyCol(1, Settings.Width - (Settings.ShowScore ? 78 : 18))
LV_ModifyCol(2, (Settings.ShowScore ? 60 : 0))
LV_ModifyCol(2, "Integer")
LV_ModifyCol(3, 0)
LV_ModifyCol(3, "Integer")
LV_ModifyCol(4, 0)
LV_ModifyCol(4, "Integer")
LV_ModifyCol(5, 0)
LV_ModifyCol(5, "Integer")
LV_ModifyCol(6, 0)

Gui Font, italic
Gui Add, Edit, % "w" Settings.Width " h25 vEditText gEditAction"
Gui Font, -italic
Gui Add, Text, x5 y5 w204 Center, Press Escape to save position
GuiControl, hide, Static1
Gui -0x20000 -Caption +LastFound +ToolWindow -Resize +MinSize300x180 +hwndhwndGui +OwnDialogs +Border
Hotkey(Settings.Hotkey, "GuiToggle")
Hotkey(Settings.WindowHotkey, "WindowSwitcher")
Hotkey("Delete", "Hotkey", hwndGui)
Hotkey("TAB", "Hotkey", hwndGui)
Hotkey("Enter", "Hotkey", hwndGui)
Hotkey("Escape", "Hotkey", hwndGui)
Hotkey("^Backspace", "Hotkey", hwndGui)
Hotkey("MButton", "Hotkey", hwndGui)
Hotkey("WheelUp", "Hotkey", hwndGui)
Hotkey("WheelDown", "Hotkey", hwndGui)
Hotkey("Up", "Hotkey", hwndGui)
Hotkey("Down", "Hotkey", hwndGui)
EditAction("")
print("Finished startup")
return

LaunchParam() {
	p = %1%
}

GuiToggle:
if (WinExist("ahk_id" hwndGui)) {
	if !(WinActive("ahk_id" hwndGui)) {
		WinActivate % "ahk_id" hwndGui
		GuiControl, focus, EditText
	} else
		gosub GuiHide
} else
	gosub GuiShow
return

GuiShow:
;GuiControl,, EditText,  % ""
Hotkey(Settings.WindowHotkey, "Off")
Gui Show, % "x" Settings.X " y" Settings.Y " w" Settings.Width " h" Settings.Height " hide", % AppName
DllCall("AnimateWindow", "UInt", hwndGui, "Int", 65, "UInt", "0xa0000")
Gui Show
GuiControl, focus, Edit1
GuiControl -Redraw, Edit1 ; this has to be here to
GuiControl +Redraw, Edit1 ; fix a graphical glitch..
GuiControl -Redraw, MyListView ; this might aswell..
GuiControl +Redraw, MyListView ; who knows, seems to work
return

GuiHide:
Hotkey(Settings.WindowHotkey, "On")
DllCall("AnimateWindow", "UInt", hwndGui, "Int", 65, "UInt", "0x90000")
GuiControl,, EditText, % ""
Gui Hide
return

Submit(input) {
	Print("Input: " input)
	if (InStr(input, "/") = 1) {
		LV_GetText(type, 1)
		LV_GetText(text, LV_GetNext())
		if (type = "AHK Documentation:") {
			if (FileExist(Substr(A_AhkPath, 1, InStr(A_AhkPath, "\",, 0)) "AutoHotkey.chm")) {
				if (Settings.ClosePreviousHelpWindow) && (WinExist("AutoHotkey Help"))
					WinClose
				run % "hh mk:@MSITStore:" Substr(A_AhkPath, 1, InStr(A_AhkPath, "\",, 0)) "AutoHotkey.chm::" IniRead("docslist.ini", text, "url")
			}
			else
				run % "http://www.ahkscript.org" IniRead("docslist.ini", text, "url")
			gosub GuiHide
		} else {
			if (!InStr(input, " ")) && (text <> "Result")
				Cmd(SubStr(text, 1, InStr(text, " - ") - 1))
			else
				Cmd(SubStr(input, 2))
		}
	} else {
		LV_GetText(text, LV_GetNext())
		if (text = "Result")
			return
		gosub GuiHide
		Print("Starting: " text)
		Run(IniRead("items.ini", text, "Directory"))
	}
}

MenuHandler(menuitem) {
	if (menuitem = "Show Columbus") {
		gosub GuiToggle
	} else

	if (menuitem = "Reset GUI position") {
		GuiMove("reset")
	} else

	if (menuitem = "Settings") {
		Settings()
	} else

	if (menuitem = "Manager") {
		Manager()
	} else

	if (menuitem = "Exit") {
		ExitApp
	}
}

Cmd(cmd) {
	if (cmd = "manager") {
		Manager()
	} else

	if (cmd = "uninstall") {
		RegDelete, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run, % AppName
		SetWorkingDir, C:\
		Loop
			FileRemoveDir % AppDirectory, 1
		until !ErrorLevel
		FileDelete % A_ScriptFullPath
		ExitApp
	} else

	if (InStr(cmd, "run") = 1) {
		run % A_ScriptFullPath " " SubStr(cmd, InStr(cmd, " ",, 0) + 1)
	} else

	if (SubStr(cmd, 1, 1) = "g") {
		gosub GuiHide
		run % "https://www.google.com/search?q=" SubStr(cmd, 3)
	} else

	if (SubStr(cmd, 1, 1) = "w") {
		gosub GuiHide
		run % "https://www.wolframalpha.com/input/?i=" UriEncode(SubStr(cmd, 3))
	}

	if (cmd = "settings") {
		Settings()
	} else

	if (cmd = "update") {
		CheckForUpdates(true)
	} else

	if (InStr(cmd, "move") = 1) {
		GuiMove(SubStr(cmd, 6) = "reset" ? "reset" : "")
	} else

	if (cmd = "reset") {
		ResetAll()
	} else

	if (Contains(cmd, "about|help")) {
		Gui 1: +Disabled
		Gui 6: Margin, 5, 5
		Gui 6: Color, 353535
		Gui 6: Font, s10
		Gui 6: Add, Text, x0 w300 Center cWhite, Columbus v%AppVersion%
		if (cmd = "about") {
			Gui 6: Add, Text, x0 w300 Center cWhite, Written by Runar Borge in AutoHotkey
			Gui 6: Font, s8
			Gui 6: Add, Text, x5 y60 w290 cWhite, I would just like to thank some people:
			Gui 6: Add, Text, x5 w290 cWhite, tidbit - massive help with ideas, bugs and icon!
			Gui 6: Add, Text, x5 w290 cWhite, arbiter34 - helped with fetching the commandlist!
			Gui 6: Add, Text, x5 w290 cWhite, AfterLemon - ALSO helped with the commandlist!
			Gui 6: Add, Text, x5 w290 cWhite, maestrith - inspiration and code setup ideas!
			Gui 6: Add, Text, x5 w290 cWhite, GeekDude - always there to help @ IRC!
		} else {
			Gui 6: Add, Text, x0 w300 Center cWhite, How to use (helpfile)
			Gui 6: Font, s8
			Gui 6: Add, Text, x5 y60 w290 cWhite, How to start a program:
			Gui 6: Add, Text, x5 w290 cWhite, Have an item selected and press enter (alternatively, double click with your mouse).
			Gui 6: Add, Text, x5 w290 cWhite, 
			Gui 6: Add, Text, x5 w290 cWhite, How to delete an item:
			Gui 6: Add, Text, x5 w290 cWhite, Either use the Item Manager or press delete while having an item selected.
			Gui 6: Add, Text, x5 w290 cWhite, 
			Gui 6: Add, Text, x5 w290 cWhite, How to use the Window Switcher:
			Gui 6: Add, Text, x5 w290 cWhite, Type in your search and enter will activate the window that's selected in the listview.
			Gui 6: Add, Text, x5 w290 cWhite, 
			Gui 6: Add, Text, x5 w290 cWhite, How to restore an item:
			Gui 6: Add, Text, x5 w290 cWhite, Go into the Item Manager and drag the item from the "Hidden List" to the "Active List".
			Gui 6: Add, Text, x5 w290 cWhite, 
			Gui 6: Add, Text, x5 w290 cWhite, How to use a command:
			Gui 6: Add, Text, x5 w290 cWhite, Type / and a list of commands will appear.
			;Gui 6: Add, Text, x5 w290 cWhite, 
		}
		Gui 6: Add, Link, x30 w290 yp+30 gaboutautohotkey, <a id="1">AutoHotkey.com thread</a>
		Gui 6: Add, Link, xp+120 w290 yp gaboutahkscript, <a id="1">ahkscript.com thread</a>
		Gui 6: Show, w300, % cmd = "help" ? "Columbus - how to use" : "About Columbus"
		return

		6GuiClose:
		6GuiEscape:
		Gui 1: -Disabled
		Gui 6: Destroy
		return

		aboutahkscript:
		run http://ahkscript.org/boards/viewtopic.php?f=6&t=3478
		return

		aboutautohotkey:
		run http://www.autohotkey.com/board/topic/108566-fuzzycomp-a-fast-program-launchersearcher/
		return
	} else

	if (cmd = "tray") ; WOAH! why are you here reading secret cmds??
		Drive, Eject
	else

	if (cmd = "exit") 
		ExitApp
	else
		print("Command not found: " cmd)
}

Hotkeys(hotkey) {
	if (hotkey = "Enter") {
		gosub Submit
	} else

	if (hotkey = "Escape") {
		ControlGetText, EditText, Edit1
		if (InStr(EditText, "/") = 1)
			GuiControl,, EditText, % ""
		else
			gosub GuiHide
	} else

	if (hotkey = "TAB") {
		LV_GetText(text, 1)
		if (text = "Commands:") {
			LV_GetText(field, LV_GetNext())
			GuiControl,, EditText, % "/" SubStr(field, 1, InStr(field, " - ") - 1)
			ControlSend, Edit1, {End}
		}
	} else

	if (hotkey = "^Backspace") {
		GuiControl -Redraw, Edit1
		ControlSend, Edit1, ^+{Left}{Backspace}
		GuiControl +Redraw, Edit1
	} else 

	if (Contains(hotkey, "WheelDown|Down")) {
		LV_Modify(LV_GetNext() + 1, "Select")
		LV_Modify(LV_GetNext(), "Vis")
		sleep 22
	} else 

	if (Contains(hotkey, "WheelUp|Up")) {
		LV_Modify((LV_GetNext() = 1 ? 1 : LV_GetNext() - 1), "Select")
		LV_Modify(LV_GetNext(), "Vis")
		sleep 22
	} else

	if (hotkey = "Delete") {
		LV_GetText(text, 1)
		if (!Contains(text, "Commands:|AHK Documentation:")) {
			num := LV_GetNext()
			LV_GetText(text, num)
			LV_Delete(num)
			LV_Modify((num > LV_GetCount() ? LV_GetCount() : num), "Select")
			ItemHandler.Delete(text)
			ItemRefresh()
		}
	}
}

EditAction(input) {
	global iconlist, namelist
	static docslist

	if (InStr(input, "/docs")) && (A_AhkPath) {
		GuiControl -Redraw, MyListView
		if !(IsObject(docslist)) {
			docslist := []
			FileRead, docs, % AppDirectory "\docslist.ini"
			Loop, parse, docs, % "`n"
				if (InStr(A_LoopField, "[") = 1)
					docslist.Insert(SubStr(A_LoopField, 2, StrLen(A_LoopField) - 3))
		} LV_GetText(text, 1)
		if (input = "/docs") && (text <> "AHK Documentation:")
			ControlSend, Edit1, {Space}
		LV_Delete()
		input := SubStr(input, 7)
		for i, value in (input ? FuzzySort(input, docslist) : docslist)
			LV_Add("Icon0", docslist[i], value.score, value.contains)
		LV_ModifyCol(2, "Sort")
		LV_ModifyCol(3, "SortDesc")
		LV_ModifyCol(4, "SortDesc")
		LV_ModifyCol(5, "SortDesc")
		LV_Insert(1, "Icon0", "AHK Documentation:")
		LV_Insert(2, "Icon0")
		LV_Modify(3, "Select")
		LV_ModifyCol(6, LV_GetCount() < ((Settings.Height - 25) / 24) ? 18 : 0)
		GuiControl +Redraw, MyListView
		return
	} else

	if (InStr(input, "/g")) {
		LV_GetText(text, 1)
		if (input = "/g") && (text <> "Google search:")
			ControlSend, Edit1, {Space}
		LV_Delete()
		LV_Add("Icon0", "Google search:")
		LV_Add("Icon0", InStr(input, " ") ? SubStr(input, InStr(input, " ") + 1) : " ")
	} else 

	if (InStr(input, "/w") = 1) {
		LV_GetText(text, 1)
		if (input = "/w") && (text <> "Wolfram Alpha:")
			ControlSend, Edit1, {Space}
		LV_Delete()
		LV_Add("Icon0", "Wolfram Alpha:")
		LV_Add("Icon0", InStr(input, " ") ? SubStr(input, InStr(input, " ") + 1) : " ")
	} else 

	if (InStr(input, "/") = 1) {
		LV_GetText(text, 1)
		if (text = "Commands:") && (StrLen(input) > 1) {
			Loop % LV_GetCount() - 2 {
				LV_GetText(field, A_Index + 2)
				field := SubStr(field, 1, InStr(field, " - ") - 1)
				if (InStr(field, SubStr(input, 2)) = 1) {
					LV_Modify(A_Index + 2, "Select")
					break
				} else
					LV_Modify(LV_GetNext(), "-Select")
			}
		} else
			LV_Modify(LV_GetNext(), "-Select -focus")
		if (text = "Commands:")
			return
		LV_Delete()
		LV_Add("Icon0", "Commands:")
		LV_Add("Icon0")
		LV_Add("Icon0", "manager - open the item manager")
		LV_Add("Icon0", "settings - open the settings menu")
		if (A_AhkPath)
			LV_Add("Icon0", "docs - search through the AHK documentation")
		LV_Add("Icon0", "update - check for updates")
		LV_Add("Icon0", "g - start a google search")
		LV_Add("Icon0", "w - wolfram alpha!")
		LV_Add("Icon0", "move - move & resize gui")
		LV_Add("Icon0", "reset - resets everything")
		LV_Add("Icon0", "about - program info")
		LV_Add("Icon0", "help - how to use")
		LV_Add("Icon0", "exit - terminate the program")
	} else {
		GuiControl -Redraw, MyListView
		resort:
		LV_Delete()
		if (Settings.Fuzzy)
			for i, value in (input ? FuzzySort(input, namelist) : namelist)
				LV_Add("Icon" . iconlist[i], namelist[i], value.score, value.contains, value.abbreviation, value.beginning)
		else
			for i, value in namelist
				if (InStr(value, input))
					LV_Add("Icon" . iconlist[i], value)
		Gui 1: Default
		LV_ModifyCol(2, "Sort")
		LV_ModifyCol(3, "SortDesc")
		LV_ModifyCol(4, "SortDesc")
		LV_ModifyCol(5, "SortDesc")
		LV_ModifyCol(6, LV_GetCount() < ((Settings.Height - 25) / 24) ? 18 : 0)
		LV_Modify(1, "Select")
		ControlGetText, EditText, Edit1, % AppName
		if (EditText <> input) {
			input := EditText
			gosub resort
		} GuiControl +Redraw, MyListView
		return
	}
}

FuzzySort(needle := "", arr := "") {
	list := []
	for i, name in arr {
		score:=prefound:=0, pos:=1, approx := name
		Loop % StrLen(needle) {
			if (!Settings.ForceSequential)
				if (muddy := InStr(approx, SubStr(needle, A_Index, 1)))
					approx := SubStr(approx, 1, muddy - 1) . SubStr(approx, muddy + 1)
			if (found := InStr(SubStr(name, pos), SubStr(needle, A_Index, 1)))
				pos += found, score += prefound - found, prefound := found * -1
			else if (!muddy)
				break
			if (A_Index = StrLen(needle)) {
				list[i, "score"] := score * -1
				list[i, "contains"] := !!InStr(name, needle)
				list[i, "abbreviation"] := InStr(RegExReplace(name, "[^A-Z]"), needle) ? 1 : 0
				list[i, "beginning"] := (InStr(name, needle) = 1) || (SubStr(name, InStr(name, needle) - 1, 1) = " ")
			}
		}
	} return list
}

ItemRefresh(index := "") {
	global namelist, iconlist
	Print("Refreshing the item list..")
	namelist := []
	iconlist := []
	FileRead, temp, items.ini
	Loop, parse, temp, % "`n"
	{
		if (InStr(A_LoopField, "[") = 1) {
			i++
			name := SubStr(A_LoopField, 2, StrLen(A_LoopField) - 3)
			namelist[i] := name
			ico := IL_Add(ImageList, IniRead("items.ini", name, "Icon"), 1)
			if (ico = 0)
				ico := IL_Add(ImageList, IniRead("items.ini", name, "Directory"), 1)
			iconlist[i] := ico
		}
	}
}

ListAction(GuiEvent) {
	if (GuiEvent = "I") {
		LV_GetText(type, 1)
		if (type = "AHK Documentation:") {
			LV_GetText(text, LV_GetNext())
			if (text = "AHK Documentation:") || (text = "") 
				ToolTip
			else {
				WinGetPos, x, y,,, ahk_id%hwndGui%
				ToolTip % ((desc := IniRead("docslist.ini", text, "desc")) = "ERROR") ? "Documentation does not exist for this entry." : desc, x, y - 25
			}
		} else
			ToolTip
	}
	if (GuiEvent = "Normal") || (GuiEvent = "RightClick") {
		GuiControl, focus, EditText
	} else if (GuiEvent = "DoubleClick") {
		ControlGetText, EditText, Edit1
		GuiControl,, EditText, % ""
		Submit(EditText)
	}
}

WindowSwitcher() {
	static
	if (WinExist("ahk_id" hwndWindowSwitcher)) {
		gosub 8GuiEscape
		return
	} Gui 1: +Disabled
	Gui 8: Default
	Hotkey(Settings.Hotkey, "Off")
	Gui 8: Font, cWhite s10
	Gui 8: Color, 454545, 454545
	Gui 8: Add, Button, Hidden gQuickSubmit Default
	Gui 8: Add, Edit, x0 y0 w505 h25 vQuickInput gQuickAction
	Gui 8: Add, ListView, x-3 y25 w508 h9999 gQuickListView -Grid -LV0x10 +LV0x20 -E0x200 +LV0x100 -TabStop -Hdr -Multi +AltSubmit, Result|Rating|contains|beginning
	Gui 8: Show, % "x" A_ScreenWidth / 2 - 250 " y" A_ScreenHeight / 2 - 115 " w500 h225", WindowSwitcher
	LV_ModifyCol(2, "Integer")
	LV_ModifyCol(3, "Integer")
	LV_ModifyCol(4, "Integer")
	Gui 8: -Caption +LastFound +AlwaysOnTop +Border hwndhwndWindowSwitcher
	hwnd := WinExist()
	Hotkey("^Backspace", "QuickBackspace", hwnd)
	Hotkey("WheelUp", "QuickScroll", hwnd)
	Hotkey("WheelDown", "QuickScroll", hwnd)
	Hotkey("Up", "QuickScroll", hwnd)
	Hotkey("Down", "QuickScroll", hwnd)
	DetectHiddenWindows off
	WinGet, processes, list
	processlist := []
	loop % processes {
		WinGetTitle, output, % "ahk_id" processes%A_Index%
		if (output <> "") && (!Contains(output, "Start|WindowSwitcher|Program Manager")) {
			i++
			processlist[i] := output
		}
	}

	QuickAction:
	Gui 8: Default
	Gui 8: Submit, NoHide
	LV_ModifyCol(1, Settings.ShowScore ? 470 : 508)
	LV_ModifyCol(2, Settings.ShowScore ? 40 : 0)
	LV_ModifyCol(3, 0)
	LV_ModifyCol(4, 0)
	LV_Delete()
	if (Settings.Fuzzy)
		for index, value in (QuickInput ? FuzzySort(QuickInput, processlist) : processlist)
			LV_Add(, processlist[index], value.score, value.contains, value.beginning)
	else
		for index, value in processlist
			if (InStr(value, QuickInput))
				LV_Add(, processlist[index])
	LV_ModifyCol(2, "Sort")
	LV_ModifyCol(3, "SortDesc")
	LV_ModifyCol(4, "SortDesc")
	LV_Modify(1, "Select")
	Gui 8: Show, % "h" LV_GetCount() * 20 + 25
	return

	QuickBackspace:
	Gui 8: Default
	GuiControl 8: -Redraw, Edit1
	ControlSend, Edit1, ^+{Left}{Backspace}
	GuiControl 8: +Redraw, Edit1
	return

	QuickScroll:
	Gui 8: Default
	if (Contains(A_ThisHotkey, "WheelDown|Down")) {
		LV_Modify(LV_GetNext() + 1, "Select")
		LV_Modify(LV_GetNext(), "Vis")
		sleep 21
	} else if (Contains(A_ThisHotkey, "WheelUp|Up")) {
		LV_Modify((LV_GetNext() = 1 ? 1 : LV_GetNext() - 1), "Select")
		LV_Modify(LV_GetNext(), "Vis")
		sleep 21
	} GuiControl 8: focus, QuickInput
	return

	QuickListView:
	if (A_GuiEvent <> "DoubleClick")
		return

	QuickSubmit:
	LV_GetText(text, LV_GetNext())
	gosub 8GuiClose
	WinActivate % text
	return

	8GuiEscape:
	Gui 8: +LastFound
	DllCall("AnimateWindow", "UInt", WinExist(), "Int", 65, "UInt", "0x90000")
	8GuiClose:
	Hotkey(Settings.Hotkey, "On")
	Gui 1: +LastFound
	hwnd := WinExist()
	Hotkey("^Backspace", "Hotkey", hwnd)
	Hotkey("WheelUp", "Hotkey", hwnd)
	Hotkey("WheelDown", "Hotkey", hwnd)
	Hotkey("Up", "Hotkey", hwnd)
	Hotkey("Down", "Hotkey", hwnd)
	Gui 1: -Disabled
	Gui 8: Destroy
	return
}

Manager() {
	static
	if (WinExist("ahk_id" hwndManager)) {
		WinActivate
		return
	}
	Hotkey(Settings.Hotkey, "Off")
	Hotkey(Settings.WindowHotkey, "Off")
	Gui 1: +Disabled
	Gui 3: Default
	Gui 3: Color, 383838, 454545
	Gui 3: Add, Text, w200 Center cWhite, Visible items
	Gui 3: Add, Text, yp xp+270 w200 Center cWhite, Hidden items
	Gui 3: Add, ListView, x10 h300 vActiveListView gActiveLabel -LV0x10 -Multi NoSortHdr NoSort -Hdr cWhite, Active
	Gui 3: Add, ListView, hp xp+250 yp vDeletedListView gDeletedLabel -LV0x10 -Multi NoSortHdr NoSort -Hdr cWhite, Deleted
	Gui 3: Add, Text, y335 x10 w440 cWhite, Drag items between the two lists to organize.
	Gui 3: Add, Button, yp-5 x460 gmanagersave, Save
	Gui 3: ListView, ActiveListView
	Gui 3: Show,, Item Manager
	Gui 3: -0x20000 hwndhwndManager
	ManagerList := []
	FileRead, temp, items.ini
	gosub loopfile
	LV_ModifyCol(1, 218)
	Gui 3: ListView, DeletedListView
	FileRead, temp, deleted_items.ini
	gosub loopfile
	LV_ModifyCol(1, 218)
	return

	loopfile:
	Loop, parse, temp, % "`n"
	{
		if (InStr(A_LoopField, "[") = 1) {
			current := SubStr(A_LoopField, 2, StrLen(A_LoopField) - 3)
			LV_Add("Icon0", current)
		} ManagerList[current] .= A_LoopField "`n"
	}
	return

	DeletedLabel:
	ActiveLabel:
	Gui 3: ListView, % "SysListView32" . (A_ThisLabel = "DeletedLabel" ? "2" : "1")
	if (A_GuiEvent = "D") {
		LV_GetText(name, A_EventInfo)
		while (GetKeyState("LButton", "P")) {
			MouseGetPos,,,,control
			ToolTip % name
			sleep 5
		} ToolTip
		if (control = "SysListView32" . (A_ThisLabel = "DeletedLabel" ? "1" : "2")) {
			LV_Delete(A_EventInfo)
			Gui 3: ListView, % "SysListView32" . (A_ThisLabel = "DeletedLabel" ? "1" : "2")
			templist:=""
			Loop % LV_GetCount() {
				LV_GetText(text, A_Index)
				templist .= text "`n"
				count := A_Index
			}
			if (LV_GetCount() = 0) {
				LV_Add(, name)
				return
			} rand := Random(1, count)
			LV_Delete()
			Loop, parse, templist, % "`n"
			{
				if (A_Index = rand)
					LV_Add(, name)
				if (A_LoopField)
					LV_Add(, A_LoopField)
			}
		}

	}
	return

	managersave:
	FileDelete items.ini
	FileDelete deleted_items.ini
	Gui 3: ListView, SysListView321
	Loop % LV_GetCount() {
		LV_GetText(text, A_Index)
		FileAppend % ManagerList[text], items.ini
	} Gui 3: ListView, SysListView322
	Loop % LV_GetCount() {
		LV_GetText(text, A_Index)
		FileAppend % ManagerList[text], deleted_items.ini
	}

	3GuiEscape:
	3GuiClose:
	ItemRefresh()
	Gui 3: Destroy
	Gui 1: Default
	Gui 1: +LastFound
	hwnd := WinExist()
	Hotkey(Settings.Hotkey, "On")
	Hotkey(Settings.WindowHotkey, "On")
	Gui 1: -Disabled
	WinActivate ahk_class%hwnd%
	GuiControl, focus, EditText
	GuiControl,, EditText, % ""
	return
}

Settings() {
	static
	if (WinExist("ahk_id" hwndSettings)) {
		WinActivate
		return
	}
	Hotkey(Settings.Hotkey, "Off")
	Hotkey(Settings.WindowHotkey, "Off")
	Gui 1: +Disabled
	Settings.preHotkey := Settings.Hotkey
	Settings.preWindowHotkey := Settings.WindowHotkey
	Gui 2: Add, Tab2, h128 w180, General|Searcher|Hotkeys
	Gui 2: Tab, General
	Gui 2: Add, CheckBox, % "vStartUp Checked" Settings.StartUp, Launch at startup
	Gui 2: Add, CheckBox, % "vUpdateCheck Checked" Settings.UpdateCheck, Check for updates
	Gui 2: Add, Checkbox, % "vDebug Checked" Settings.Debug, Show console
	Gui 2: Tab, Searcher
	Gui 2: Add, Text,, Searching method:
	Gui 2: Add, Radio, % "vSearchMethod Checked" (Settings.Fuzzy = 1 ? 1 : 0), Fuzzy
	Gui 2: Add, Radio, % "x80 yp Checked" (Settings.Fuzzy = 0 ? 1 : 0), Normal
	Gui 2: Add, CheckBox, % "yp+18 xp-58 vForceSequential Checked" (Settings.ForceSequential = 1 ? 1 : 0), Force sequential
	Gui 2: Add, CheckBox, % "vShowScore Checked" (Settings.ShowScore = 1 ? 1 : 0), Show item score
	Gui 2: Tab, Hotkeys
	Gui 2: Add, Text,, Hotkey:
	Gui 2: Add, Hotkey, vHotkey, % Settings.Hotkey
	Gui 2: Add, Text,, WindowSwitcher hotkey:
	Gui 2: Add, Hotkey, vWindowHotkey, % Settings.WindowHotkey
	Gui 2: Tab
	Gui 2: Add, Button, gsettingsreset w65 x10, Reset all
	Gui 2: Add, Button, gsettingssave yp w50 x140, Save
	Gui 2: Show,, Settings
	Gui 2: -0x20000 hwndhwndSettings
	return

	settingsreset:
	gosub 2GuiEscape
	ResetAll()
	return

	settingssave:
	Gui 2: Submit, NoHide
	if (Hotkey = "") || (WindowHotkey = "") {
		Error("You have to enter a hotkey.")
		return
	} else if (Hotkey = WindowHotkey) {
		Error("The hotkeys have to be unique.")
		return
	} Gui 1: Default
	Settings.Write("Hotkey", Hotkey)
	Settings.Write("WindowHotkey", WindowHotkey)
	Settings.Write("StartUp", StartUp)
	Settings.Write("UpdateCheck", UpdateCheck)
	Settings.Write("ShowScore", ShowScore = 1 ? 1 : 0)
	Settings.Write("Fuzzy", SearchMethod = 1 ? 1 : 0)
	Settings.Write("Debug", Debug = 1 ? 1 : 0)
	Settings.Write("ForceSequential", ForceSequential = 1 ? 1 : 0)
	Hotkey(Settings.Hotkey, Settings.Hotkey = Settings.preHotkey ? "On" : "GuiToggle")
	Hotkey(Settings.WindowHotkey, Settings.WindowHotkey = Settings.preWindowHotkey ? "On" : "WindowSwitcher")
	if (Settings.StartUp)
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run, % AppName, % A_ScriptFullPath
	else
		RegDelete, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run, % AppName
	LV_ModifyCol(1, Settings.Width - (Settings.ShowScore ? 78 : 18))
	LV_ModifyCol(2, (Settings.ShowScore ? 60 : 0))
	if (Debug)
		print()

	2GuiEscape:
	2GuiClose:
	Hotkey(Settings.Hotkey, "On")
	Gui 2: Destroy
	Gui 1: -Disabled
	WinActivate ahk_id %hwndGui%
	GuiControl, focus, EditText
	return
}

GuiMove(reset := "") {
	if (reset) {
		Settings.Write("Width", "500")
		Settings.Write("Height", "425")
		Settings.Write("X", A_ScreenWidth - 502)
		Settings.Write("Y", A_ScreenHeight - 466)
		if (WinExist("ahk_id" hwndGui))
			Gui Show, % "x" Settings.X " y" Settings.Y " w" Settings.Width " h" Settings.Height, % AppName
		return
	}
	Hotkey("Escape", "stopmove", hwndGui)
	Hotkey(Settings.Hotkey, "Off")
	GuiControl, hide, MyListView
	GuiControl, Disable, MyListView
	GuiControl, hide, EditText
	GuiControl, Disable, EditText
	GuiControl, show, Static1
	if !(WinActive("ahk_id" hwndGui))
		gosub GuiShow
	Gui +Resize
	return

	stopmove:
	Hotkey("Escape", "GuiHide", hwndGui)
	Hotkey(Settings.Hotkey, "On")
	Gui -Resize
	GuiControl, show, MyListView
	GuiControl, show, EditText
	GuiControl, Hide, Static1
	GuiControl, Enable, MyListView
	GuiControl, Enable, EditText
	GuiControl, focus, EditText
	WinGetPos, x, y, w, h, ahk_id %hwndGui%
	if (x&&y&&w&&h) {
		Settings.Write("X", x)
		Settings.Write("Y", y)
		Settings.Write("Width", w)
		Settings.Write("Height", h)
	} else {
		Settings.ResetCoordinates()
		Error("Error: Coordinates were not saved.")
	} return
}

GuiDropFiles(GuiEvent) {
	global ItemHandler
	Loop, parse, GuiEvent, % "`n"
	{
		if (!FileExist(A_LoopField)) {
			Error(A_LoopField " could not be added.")
			continue
		} FileGetShortcut, % A_LoopField, ShortcutTarget
		SplitPath, A_LoopField,,,, name
		if (ErrorLevel = 1)
			ShortcutTarget := A_LoopField
		if (name&&ShortcutTarget)
		ItemHandler.Insert(name, ShortcutTarget, ShortcutTarget, Random(0, 45) / 100)
		else {
			Error(name " could not be added.")
			continue
		} addedlist .= name "`n"
	} ItemRefresh()
	TrayTip,, Added to list:`n%addedlist%
	GuiControl,, EditText, % ""
}

ResetAll() {
	global ItemHandler
	MsgBox, 4, Warning, This will reset every aspect of the program. Are you sure you want to continue?
	ifMsgBox no
		return
	Print("Resetting everything..")
	Gui 1: Default
	LV_Delete()
	Settings.Defaults()
	FileDelete items.ini
	FileDelete deleted_items.ini
	ItemHandler.Search()
	ItemRefresh()
	WinActivate ahk_class %hwndGui%
	GuiControl,, EditText, % ""
}

CheckForUpdates(notify := false) {
	static
	redownload:
	url = www.pastebin.com
	RunWait, ping.exe %url% -n 1,, Hide UseErrorlevel
	if ErrorLevel
	{
		print("Update page unavaliable")
		return
	} else
		print("Checking for updates..")
	info := URLGet("http://pastebin.com/raw.php?i=HPW20v2F")
	if (InStr(info, "DOCTYPE")) {
		Error("Master file was not fetched correctly.")
		return
	} Loop, parse, info, % "`n"
	{
		temp := SubStr(A_LoopField, 1, InStr(A_LoopField, "=") - 1)
		if (temp = "updateinfo") {
			updateinfo := true
			continue
		} if (updateinfo) {
			updateinfo := true
			updatecontents .= A_LoopField "`n"
		} else {
			%temp% := SubStr(A_LoopField, InStr(A_LoopField, "=") + 1, (StrLen(A_LoopField) - StrLen(temp) - 2))
			Gui 4: Add, Text, % "x0 y0 v" temp " Hidden", % %temp%
		}
	} temp:=""

	if !(version && exe && ahk) {
		Error("Update file was not fetched correctly.")
		return
	}

	if (A_AhkPath) {
		Print("Downloading documentation list..")
		FileReadLine, docsversion, % AppDirectory "\docslist.ini", 1
		if (docsversion < docsver)
			FileDelete % AppDirectory "\docslist.ini"

		if (!FileExist(AppDirectory "\docslist.ini"))
			FileAppend % URLGet(docs), % AppDirectory "\docslist.ini"
	}

	if (AppVersion < version) {
		Print("Displaying update prompt")
		Gui 4: Margin, 5, 5
		Gui 4: Add, Text, x5 y5, A new update is avaliable.
		Gui 4: Font, s12
		Gui 4: Add, Text,, Newest version: %version%
		Gui 4: Font, s8
		Gui 4: Add, Text,, Download as:
		Gui 4: Add, Radio, % "vDownloadFileExt Checked" (Settings.DownloadFileExt = "exe" ? 1 : 0), exe
		Gui 4: Add, Radio, % "x55 yp Checked" (Settings.DownloadFileExt = "ahk" ? 1 : 0), ahk
		Gui 4: Font, s11
		Gui 4: Add, Text, x5, Features added since your last update:
		Gui 4: Add, Button, yp-8 x365 gupdate, Update
		Gui 4: Add, Button, yp xp+70 g4GuiClose, Cancel
		Loop, parse, updatecontents, % "`n"
			if (InStr(A_LoopField, AppVersion ":") = 1)
				break
			else
				if !(InStr(A_LoopField, "0") = 1) && !(InStr(A_LoopField, "1") = 1)
					if (StrLen(A_LoopField) > 1)
						cont2 .= A_LoopField "`n"
		Gui 4: Add, Edit, w490 x5 h250 ReadOnly c505050, % cont2
		Gui 4: -0x20000
		Gui 4: Show, w500, % AppName " Updater"
	} else if notify
		MsgBox,, % AppName, No updates found.

	return

	update:
	Print("Updating!")
	Gui Submit
	Settings.Write("DownloadFileExt", DownloadFileExt = 1 ? "exe" : "ahk")
	if (Settings.DownloadFileExt = "exe") {
		TrayTip,, Downloading update.. (might take a few seconds)
		UrlDownloadToFile, % exe, % AppDirectory "\download"
	} else
		FileAppend % URLGet(ahk), % AppDirectory "\download"
	FileMove, % A_ScriptFullPath, % AppDirectory "\old"
	FileMove, % AppDirectory "\download", % A_ScriptDir "\" AppName "." Settings.DownloadFileExt
	sleep 200
	run % A_ScriptDir "\" AppName "." Settings.DownloadFileExt,, UseErrorLevel
	if (ErrorLevel = "ERROR") {
		MsgBox, 4, % AppName, Oops, download failed. Do you want to retry?
		ifMsgBox no
		{
			FileDelete % A_ScriptDir "\" AppName "." Settings.DownloadFileExt
			FileMove % AppDirectory "\old", % A_ScriptFullPath
		} else
			gosub redownload
		return
	} ExitApp
	return

	4GuiEscape:
	4GuiClose:
	Gui 4: Destroy
	return
}

Hotkey(key, label := "", hwnd := "") {
	if (hwnd)
		Hotkey, IfWinActive, % "ahk_id" hwnd
	else
		Hotkey, IfWinActive	
	Hotkey, % key, % label, UseErrorLevel
	if ErrorLevel
		Error("Hotkey command failed`n`nHotkey: " key "`nLabel: " label "`n`nError code:" ErrorLevel)
}

GuiSize:
GuiControl, Move, EditText, % "w" A_GuiWidth " y" A_GuiHeight - 25
GuiControl, Move, MyListView, % "w" A_GuiWidth " h" A_GuiHeight - 25
GuiControl, Move, Static1, % "x" A_GuiWidth / 2 - 102 " y" A_GuiHeight / 2 - 18
LV_ModifyCol(1, A_GuiWidth - (Settings.ShowScore ? 78 : 18))
LV_ModifyCol(2, (Settings.ShowScore ? 60 : 0))
return

GuiDropFiles:
GuiDropFiles(A_GuiEvent)
return

ListVars:
ListVars
return

Hotkey:
Hotkeys(A_ThisHotkey)
return

ListAction:
ListAction(A_GuiEvent)
return

EditAction:
Gui Submit, NoHide
EditAction(EditText)
return

WindowSwitcher:
WindowSwitcher()
return

MenuHandler:
MenuHandler(A_ThisMenuItem)
return

Submit:
Gui Submit, NoHide
GuiControl,, EditText, % ""
Submit(EditText)
return

ControlGetText(control) {
	ControlGetText, text, % control
	return text
}

Run(file) {
	run % file, % SubStr(file, 1, InStr(file, "\",, 0))
}

Exit:
ExitApp
return

Class inifile {
	__New(file) {
		this.file := file
	}

	Read(section, key) {
		IniRead, out, % this.file, % section, % key, % A_Space
		return out
	}

	Write(section, key, value) {
		IniWrite, % value, % this.file, % section, % key
	}

	Delete(section, key := "") {
		IniDelete, % this.file, % section, % key
	}
}

Class Settings {
	__New() {
		this.s := new inifile(AppDirectory "\settings.ini")
		if (Settings.StartUp)
			RegWrite, REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run, % AppName, % A_ScriptFullPath
		else
			RegDelete, HKEY_LOCAL_MACHINE, SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run, % AppName
	}

	Defaults() {
		this.s.Write("Settings", "Hotkey", "^!P")
		this.s.Write("Settings", "WindowHotkey", "^!O")
		this.s.Write("Settings", "StartUp", "1")
		this.s.Write("Settings", "UpdateCheck", "1")
		this.s.Write("Settings", "ShowScore", "1")
		this.s.Write("Settings", "Fuzzy", "1")
		this.s.Write("Settings", "Debug", "0")
		this.s.Write("Settings", "ForceSequential", "1")
		this.s.Write("Settings", "ClosePreviousHelpWindow", "0")
		this.s.Write("Settings", "DownloadFileExt", FileExt(A_ScriptFullPath))
		this.ResetCoordinates()
	}

	ResetCoordinates() {
		this.s.Write("Settings", "X", A_ScreenWidth - 502)
		this.s.Write("Settings", "Y", A_ScreenHeight - 466)
		this.s.Write("Settings", "Width", "500")
		this.s.Write("Settings", "Height", "425")
	}

	Delete(key := "") {
		s.Delete("Settings", key)
	}

	Read(key := "") {
		if (key)
			msgbox % s.Read("Settings", key)
		if (!this.Hotkey := this.s.Read("Settings", "Hotkey"))
			this.s.Write("Settings", "Hotkey", "^!P")

		if (!this.WindowHotkey := this.s.Read("Settings", "WindowHotkey"))
			this.s.Write("Settings", "WindowHotkey", "^!O")

		if (!this.StartUp := this.s.Read("Settings", "StartUp"))
			this.s.Write("Settings", "StartUp", "1")

		if (!this.UpdateCheck := this.s.Read("Settings", "UpdateCheck"))
			this.s.Write("Settings", "UpdateCheck", "1")

		if (!this.ShowScore := this.s.Read("Settings", "ShowScore"))
			this.s.Write("Settings", "ShowScore", "1")

		if (!this.Fuzzy := this.s.Read("Settings", "Fuzzy"))
			this.s.Write("Settings", "Fuzzy", "1")

		if (!this.Debug := this.s.Read("Settings", "Debug"))
			this.s.Write("Settings", "Debug", "0")

		if (!this.ForceSequential := this.s.Read("Settings", "ForceSequential"))
			this.s.Write("Settings", "ForceSequential", "0")

		if (!this.ClosePreviousHelpWindow := this.s.Read("Settings", "ClosePreviousHelpWindow"))
			this.s.Write("Settings", "ClosePreviousHelpWindow", "0")

		if (this.DownloadFileExt := this.s.Read("Settings", "DownloadFileExt"))
			this.s.Write("Settings", "DownloadFileExt", FileExt(A_ScriptFullPath))

		if (!this.X := this.s.Read("Settings", "X"))
			this.s.Write("Settings", "X", A_ScreenWidth - 502)

		if (!this.Y := this.s.Read("Settings", "Y"))
			this.s.Write("Settings", "Y", A_ScreenHeight - 466)

		if (!this.Width := this.s.Read("Settings", "Width"))
			this.s.Write("Settings", "Width", "500")

		if (!this.Height := this.s.Read("Settings", "Height"))
			this.s.Write("Settings", "Height", "425")

	}

	Write(key, value) {
		this.s.Write("Settings", key, value)
		this[key] := value
	}
}

Class ItemHandler {
	
	__New() {
		this.blocked_names := "update|setup|driver"
		this.blocked_dirs := "{|%|~|system32|unin|setup|steamapps"
	}

	Search() {
		this.scan("HKEY_CURRENT_USER", "Software\Microsoft\Windows\CurrentVersion\Uninstall")
		this.custom()
		this.chrome_apps()
		this.steam_games()
		this.scan("HKEY_LOCAL_MACHINE", "Software\Microsoft\Windows\CurrentVersion\Uninstall")
		this.scan("HKEY_LOCAL_MACHINE", "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
	}

	Delete(item) {
		IniWrite("deleted_items.ini", item, "Directory", IniRead("items.ini", item, "Directory"))
		IniWrite("deleted_items.ini", item, "Icon", IniRead("items.ini", item, "Icon"))
		IniDelete("items.ini", item)
		print("deleted: " item)
	}

	Verify(file) {
		FileRead, temp, % file
		Loop, parse, temp, % "`n"
		{
			if (InStr(A_LoopField, "[") = 1)
				item := SubStr(A_LoopField, 2, StrLen(A_LoopField) - 3)
			else if (InStr(A_LoopField, "Directory=") = 1)
				if (!FileExist(SubStr(A_LoopField, 11, StrLen(A_LoopField) - 11))) && (!InStr(A_LoopField, "steam://")) {
					IniDelete(file, item)
					print("Removed (non-existent file): " item)
				}
		}
	}

	Sort(type) {
		Ini := []
		FileRead, temp, items.ini
		Loop, parse, temp, % "`n"
		{
			if (InStr(A_LoopField, "[") = 1) {
				name := A_LoopField
				namelist .= A_LoopField "`n"
			} if (A_LoopField = "")
				break
			Ini[name] .= A_LoopField "`n"
		} FileDelete items.ini
		if (type = "random")
			Sort, namelist, Random
		else if (type = "up")
			Sort, namelist
		else if (type = "down")
			Sort, namelist, R
		else
			TrayTip, Error, "%type%" is not a valid parameter.
		Loop, parse, namelist, % "`n"
			FileAppend % Ini[A_LoopField], items.ini
	}

	Insert(name, dir, icon, pos) {
		Ini := []
		if (IniRead("items.ini", name, "Directory") <> "ERROR")
			return "Item already exists."
		FileRead, temp, items.ini
		Loop, parse, temp, % "`n"
		{
			if (A_LoopField = "")
				continue
			if (InStr(A_LoopField, "[") = 1)
				count++
			Ini[count] .= A_LoopField "`n"
		} FileDelete items.ini
		Loop % Ini.MaxIndex() {
			if (count * pos < A_Index / 3) && (!done) {
				FileAppend % "[" name "]`r`nDirectory=" dir "`r`nIcon=" icon "`r`n", items.ini
				done := true
			} FileAppend % Ini[A_Index], items.ini
		}

	}

	Restore(item) {
		FileRead, temp, items.ini
		StringReplace, temp, temp, `n, `n, UseErrorLevel
		total_lines := ErrorLevel
		pos := IniRead("deleted_items.ini", item, "pos")
		Loop, parse, temp, % "`n"
		{
			append .= A_LoopField "`n"
			if (((A_Index) / total_lines) > pos) && !(SubStr(A_LoopField, 1, 1) = "[") && !(SubStr(A_LoopField, 1, 1) = "D") && !(done) {
				done := true
				append .= "[" item "]`r`nDirectory=" IniRead("deleted_items.ini", item, "Directory") "`r`nIcon=" IniRead("deleted_items.ini", item, "Icon") "`r`n"
			}
		} IniDelete("deleted_items.ini", item)
		FileDelete items.ini
		FileAppend % append, items.ini
	}
	
	add(name, dir, icon) {
		static created
		if !created
			FileGetTime, created, % AppDirectory "\items.ini", C
		if !FileExist(AppDirectory "\items.ini")
			created := A_Now
		if !(Contains(dir, this.blocked_dirs)) && !(Contains(name, this.blocked_names)) && (IniRead("deleted_items.ini", name, "Directory") = "ERROR") && (IniRead("items.ini", name, "Directory") = "ERROR") {
			time := created
			time -= A_Now, s
			if (time < -20)
				this.Insert(name, dir, icon, Random(1, 40) / 100)
			else {
				IniWrite("items.ini", name, "Directory", RegExReplace(dir, """", ""))
				IniWrite("items.ini", name, "Icon", RegExReplace(icon, """", ""))	
			}
		}
	}

	scan(key, subkey) {
		Loop, % key, % subkey, 1, 1
		{
			if (A_LoopRegName = "DisplayName") {
				RegRead name
				icon := RegRead(A_LoopRegKey, A_LoopRegSubKey, "DisplayIcon")
				if (dir := icon) {
					dir := RegExReplace(dir, """", "")
					if (in_dir := RegRead(A_LoopRegKey, A_LoopRegSubKey, "InstallLocation")) {
						if !(InStr(dir, ".exe"))
							dir := in_dir
					} if (InStr(dir, ","))
						dir := SubStr(dir, 1, InStr(dir, ",") - 1)
					if (FileExt(dir) <> "exe") || Contains(dir, "unin|setup")
						dir := this.search_directory(name, dir, icon)
					if (name&&dir&&icon)
						this.add(name, dir, icon)
				}
			}
		}
	}

	search_directory(name, dir, icon := "") {
		if (Contains(dir, "steam\games|{|%|~|system32|javaw"))
			return
		if (SubStr(dir, -1) <> "\") {
			if (InStr(dir, "."))
				dir := SubStr(dir, 1, InStr(dir, "\",, 0) + 1)
			else
				dir .= "\"
		} if (InStr(name, ":"))
			name := RegExReplace(name, ":", "")
		Loop, % dir "\*.exe", 1, 1
		{
			if (Contains(A_LoopFileName, RegExReplace(name, " ", "|"))) {
				print("found: " A_LoopFileFullPath)
				return A_LoopFileFullPath
			}
		}
	}

	custom() {
		if (dir := RegRead("HKEY_LOCAL_MACHINE", "SOFTWARE\Wow6432Node\Fraps", "Install_Dir"))
			this.add("Fraps", dir "\fraps.exe", dir "\fraps.exe")
	}

	chrome_apps() { 
		Loop %A_StartMenu%\*, 1, 1
			if (InStr(A_LoopFileName, "Chrome") = 1)
				Loop %A_LoopFileLongPath%\*.*
				{
					FileGetShortcut, % A_LoopFileFullPath, targ,, args
					this.Add(SubStr(A_LoopFileName, 1, -4), targ " " args, SubStr(A_AppData, 1, -8) "\Local\Google\Chrome\User Data\Default\Web Applications\_crx_" SubStr(args, InStr(args, "--app-id=") + 9) "\" SubStr(A_LoopFileName, 1, -4) ".ico")
				}
	}

	steam_games(key := "HKEY_LOCAL_MACHINE", subkey := "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") {
		Loop, % key, % subkey, 1, 1
			if (A_LoopRegName = "DisplayName") && (InStr(SubStr(A_LoopRegSubKey, InStr(A_LoopRegSubKey, "\",, 0) + 1), "Steam App "))
				this.Add(RegRead(A_LoopRegKey, A_LoopRegSubKey, "DisplayName"), "steam://rungameid/" SubStr(SubStr(A_LoopRegSubKey, InStr(A_LoopRegSubKey, "\",, 0) + 1), InStr(SubStr(A_LoopRegSubKey, InStr(A_LoopRegSubKey, "\",, 0) + 1), " ",, 0) + 1), RegRead(A_LoopRegKey, A_LoopRegSubKey, "DisplayIcon"))
	}
}

Contains(needle, haystack) {
	return RegExMatch(needle, "i)(" haystack ")")
}

FileExt(file) {
	SplitPath, file,,, ext
	return ext
}

RegRead(root, sub, value) {
	RegRead, output, % root, % sub, % value
	return output
}

Random(min, max) {
	Random, out, % min, % max
	return out
}

RandomString(length, special := false) {
	Loop % length
		chr .= (r := Random(1, special ? 4 : 3)) = 1 ? Random(0, 9) : r = 2 ? Chr(Random(65, 90)) : r = 3 ? Chr(Random(97, 122)) : SubStr("-_?!&:", r := Random(1, 6), 1)
	return % chr
}

IniRead(file, section, key := "") {
	IniRead, output, % AppDirectory "\" file, % section, % key
	return output
}

IniWrite(file, section, key, value) {
	IniWrite, % value, % AppDirectory "\" file, % section, % key
	return ErrorLevel
}

IniDelete(file, section, key := "") {
	if key
		IniDelete, % AppDirectory "\" file, % section, % key
	else
		IniDelete, % AppDirectory "\" file, % section
}

WM_LBUTTONDOWN() {
	WinGet, style, Style
	if (Style & 0x40000) && (A_Gui = 1)
		PostMessage, 0xA1, 2
}

UriEncode(Uri) { ; thanks to GeekDude for providing this function!
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0)
	StrPut(Uri, &Var, "UTF-8")
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	while Code := NumGet(Var, A_Index - 1, "UChar")
		if (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		else
			Res .= "%" . SubStr(Code + 0x100, -1)
	SetFormat, IntegerFast, %f%
	return, Res
}

OtherInstance() { ; thanks GeekDude!
	WinGet, Wins, List, %A_ScriptFullPath% - ahk_class AutoHotkey
	Loop, %Wins%
		if (Wins%A_Index% != A_ScriptHwnd)
			return Wins%A_Index%
	return
}

; R.I.P Groupbox2()

URLGet(URL) {
	WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WebRequest.Open("GET", URL)
	WebRequest.Send()
	return WebRequest.ResponseText
}

Error(text, fatal := false) {
	Print()
	Print("Error:")
	Print(text)
	Print("Error is " fatal ? "fatal. Exiting program in 4 seconds.." : "not fatal.")
	MsgBox, 16, Columbus, % text (fatal ? "`n`nProgram will exit." : ""), 4
	if fatal
		ExitApp
}

Print(x:="") {
	static i, hwndDebug
	w:=500
	h:=600
	if (!hwndDebug) {
		Gui 99: Color,, 000000
		Gui 99: Font, c00FF00
		Gui 99: Add, ListView, x0 y0 h%h% w%w% -Hdr -LV0x20 , #|Msg
		Gui 99: +hwndhwndDebug
	}
	if (Settings.Debug) && (!WinExist("ahk_id" hwndDebug))
		Gui 99: Show, w%w% h%h%, Columbus Debug
	else if (WinExist("ahk_id" hwndDebug)) && (!Settings.Debug)
		Gui 99: Hide
	if (x = "")
		return
	i++
	Gui, +hwndhwnd
	Gui 99: Default
	LV_Add(, i, x)
	LV_Modify(LV_GetCount(), "Vis")
	Gui %hwnd%: Default
	return
}

STMS() { ; System Time in MS / STMS() returns milliseconds elapsed since 16010101000000 UT
Static GetSystemTimeAsFileTime, T1601                              ; By SKAN / 21-Apr-2014  
  if ! GetSystemTimeAsFileTime
       GetSystemTimeAsFileTime := DllCall( "GetProcAddress", UInt
                                , DllCall( "GetModuleHandle", Str,"Kernel32.dll" )
                                , A_IsUnicode ? "AStr" : "Str","GetSystemTimeAsFileTime" ) 
  DllCall( GetSystemTimeAsFileTime, Int64P,T1601  )
Return T1601 // 10000
} ; http://ahkscript.org/boards/viewtopic.php?p=17076#p17076