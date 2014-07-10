#Persistent
#Singleinstance, force
SetWorkingDir, %A_ScriptDir%
DetectHiddenWindows, on
SetBatchLines -1
#NoTrayIcon
Menu, Tray, Icon, Shell32.dll, 19
OnExit, OnExitLabel

MAX_ROWS := 100

Gui, +LastFound +AlwaysOnTop
Gui, Font, s13
Gui, Add, Text, w180 vDisplay,
Gui, Font
Gui, Add, Button, vUpdate gTestNow Section, Testar Agora!
Gui, Add, DropDownList, ys w43 vTimerT gReiniciaTimer, 5|10|30||60|120
Gui, Add, Checkbox, ys+5 vcheckAlwaysOnTop gAlways Checked, OnTop
Gui, Add, ListView, xs w200 h150 SortDesc +Grid, Hora|Resultado
LV_ModifyCol(1, 60)
LV_ModifyCol(2, 130)
Gui, Add, Progress, Vertical yp xm+210 w4 h150 cGreen vTestProgress BackgroundDDDDDD
Gui, Show,, Teste de Conexão

timer   := 0
SetTimer, Testar, 1000

Return

;=======================
; Testa a conexão
Testar:
    GuiControl,, TestProgress, % (timerT-timer)/timerT*100
    if (timer != 0)
    {
        timer--
        Return
    }
    
    GuiControl,, Display, Testando...

    URL := "http://www.google.com.br"

    If InternetCheckConnection(URL)
       newStr = Conectado!
    else 
       newStr = Erro

    ;MsgBox, % newStr
    GuiControl,, Display, % newStr
    FormatTime, now, A_Now, HH:mm:ss
    
    LV_Add("", now, newStr)
    numRows := LV_GetCount()
    if (numRows > MAX_ROWS)
        LV_Delete(numRows)

    if (newStr == "Conectado!")
    {
        Gui, Color, 00FF00
        SetTimer, Testar, Off
        Gui Flash
        Loop, 5
        {
            SoundBeep
            Sleep, 100
        }
        SetTimer, Piscar, -10
    }
    Else
    {
        Gui, Color, EEAA99
        GoSub, ReiniciaTimer
    }
Return

;=======================
; Força novo teste agora
TestNow:
    timer := 0
Return

;=======================
; Pisca fundo
Piscar:
    Loop
    {
        Gui, Flash
        Gui, Show, NA
        Gui, Color, 00FF00
        Sleep, 800
        Gui, Color, FFFF00
        Sleep, 800
    }
Return

;=======================
; Controla clique no botão Always on Top
Always:
    GuiControlGet, CheckAlwaysOnTop
    if CheckAlwaysOnTop
        Gui, +AlwaysOnTop
    else
        Gui, -AlwaysOnTop
Return

;=======================
; Altera o tempo total
ReiniciaTimer:
    GuiControlGet, timerT 
    timer := timerT
Return

;=======================
; Finaliza o script
GuiEscape:
GuiClose:
OnExitLabel:
    ExitApp
Return

InternetCheckConnection(Url="",FIFC=1) { 
    Return DllCall("Wininet.dll\InternetCheckConnection", Str,Url, Int,FIFC, Int,0) 
}
