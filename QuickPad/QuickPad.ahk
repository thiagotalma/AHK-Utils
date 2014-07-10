#NoEnv
#SingleInstance, Off
SetWorkingDir, %A_ScriptDir%
Menu, Tray, Icon, Shell32.dll, 71

Gui, +Resize +MaximizeBox +HwndMyGuiHwnd
Gui, Font, s11
Gui, Add, Edit, r20 w500 vMainEdit WantTab W600 R20
Gui, Show, AutoSize, QuickPad
CurrentFileName = 
return

GuiClose:
ExitApp

#IfWinActive QuickPad ahk_class AutoHotkeyGUI
^s::Gosub FileSave
^+s::Gosub FileSaveAs
return

GuiSize:
    if ErrorLevel = 1  ; The window has been minimized.  No action needed.
        return
    ; Otherwise, the window has been resized or maximized. Resize the Edit control to match.
    NewWidth := A_GuiWidth - 20
    NewHeight := A_GuiHeight - 20
    GuiControl, Move, MainEdit, W%NewWidth% H%NewHeight%
return

FileSave:
if CurrentFileName =   ; No filename selected yet, so do Save-As instead.
    Goto FileSaveAs
Gosub SaveCurrentFile
return

FileSaveAs:
    Gui +OwnDialogs  ; Force the user to dismiss the FileSelectFile dialog before returning to the main window.
    FileSelectFile, SelectedFileName, S16,, Salvar Arquivo, Todos os arquivos (*.*)
    if SelectedFileName =  ; No file selected.
        return
    CurrentFileName = %SelectedFileName%
    Gosub SaveCurrentFile
return

SaveCurrentFile:  ; Caller has ensured that CurrentFileName is not blank.
    IfExist %CurrentFileName%
    {
        FileDelete %CurrentFileName%
        if ErrorLevel
        {
            MsgBox The attempt to overwrite "%CurrentFileName%" failed.
            return
        }
    }
    GuiControlGet, MainEdit  ; Retrieve the contents of the Edit control.
    FileAppend, %MainEdit%, %CurrentFileName%  ; Save the contents to the file.
    ; Upon success, Show file name in title bar (in case we were called by FileSaveAs):
    Gui, Show,, QuickPad - %CurrentFileName%
return
