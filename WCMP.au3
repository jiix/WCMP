#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Res_Description=WCMP
#AutoIt3Wrapper_Res_Fileversion=1.0.4.0
#AutoIt3Wrapper_Res_ProductName=WCMP
#AutoIt3Wrapper_Res_ProductVersion=1.0.4.0
#AutoIt3Wrapper_Res_LegalCopyright=No Right Reserved
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=Y
#Au3Stripper_Parameters=/pe /sf /sv
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;#NoTrayIcon
#pragma compile(AutoItExecuteAllowed, True)
#cs ----------------------------------------------------------------------------
	AutoIt Version: 3.3.14.2
	Author:         Kyle Ch
	Script Function:
	Template AutoIt script.
#ce ----------------------------------------------------------------------------


#include <Array.au3>
#include <AutoItConstants.au3>
#include <File.au3>
#include <String.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <Misc.au3>
#include <ButtonConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ColorConstants.au3>

#Region All Over-Head
;Fix 32bit app on 64bit system problem
If @OSArch = "X64" Then DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1)
;Fix change default dir to script
FileChangeDir(@ScriptDir)
;Fix if singleton
If _Singleton(@ScriptName, 1) = 0 Then
	$Singletonmsg = MsgBox(4, "Warning", "Program is already running, do you want to reset processes?", 10)
	If $Singletonmsg = 6 Or $Singletonmsg = -1 Then RunWait(@ComSpec & ' /c taskkill /f /IM ' & @ScriptName & '&&start "" /D "' & @ScriptDir & '" "' & @ScriptFullPath & '"', '', @SW_HIDE)
	Exit
EndIf
;Add trayicon Exit Menu
Opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)
TraySetOnEvent(-7, "_show") ;left click
TraySetClick(8) ;right click
TrayCreateItem("Show Panel")
TrayItemSetOnEvent(-1, "_show")
TrayCreateItem("Exit All")
TrayItemSetOnEvent(-1, "_mainexit")

HotKeySet("!{F5}", "_mainexit") ; An Extra hotkey to terminate
;Gui on Event
Opt("GUIOnEventMode", 1)
;--------------------------GUI Starts Here--------------------------
$Form1 = GUICreate("WCMP", 606, 428)
$Button1 = GUICtrlCreateButton("Start All", 152, 16, 161, 41)
GUICtrlSetOnEvent(-1, "startall")
$Button2 = GUICtrlCreateButton("Stop All", 360, 16, 145, 41)
GUICtrlSetOnEvent(-1, "stopall")

$Label1 = GUICtrlCreateLabel("Caddy", 56, 112, 42, 17)
$Button3 = GUICtrlCreateButton("Start Caddy", 152, 96, 161, 41)
GUICtrlSetOnEvent(-1, "startcaddy")
$Button4 = GUICtrlCreateButton("Stop Caddy", 360, 96, 145, 41)
GUICtrlSetOnEvent(-1, "stopcaddy")
$Button5 = GUICtrlCreateButton("Config", 536, 96, 41, 41)
GUICtrlSetOnEvent(-1, "configcaddy")

$Label2 = GUICtrlCreateLabel("PHP", 56, 192, 42, 17)
$Button6 = GUICtrlCreateButton("Start PHP", 152, 176, 161, 41)
GUICtrlSetOnEvent(-1, "startphp")
$Button7 = GUICtrlCreateButton("Stop PHP", 360, 176, 145, 41)
GUICtrlSetOnEvent(-1, "stopphp")
$Button8 = GUICtrlCreateButton("Config", 536, 176, 41, 41)
GUICtrlSetOnEvent(-1, "configphp")

$Label3 = GUICtrlCreateLabel("MySQL", 56, 272, 42, 17)
$Button9 = GUICtrlCreateButton("Start MySQL", 152, 256, 161, 41)
GUICtrlSetOnEvent(-1, "startsql")
$Button10 = GUICtrlCreateButton("Stop MySQL", 360, 256, 145, 41)
GUICtrlSetOnEvent(-1, "stopsql")
$Button11 = GUICtrlCreateButton("Config", 536, 256, 41, 41)
GUICtrlSetOnEvent(-1, "configsql")

$Button12 = GUICtrlCreateButton("Exit All!", 360, 336, 217, 65)
GUICtrlSetOnEvent(-1, "_mainexit")
$Button13 = GUICtrlCreateButton("Open WWW Folder", 152, 336, 161, 65)
GUICtrlSetOnEvent(-1, "openwww")
GUISetState(@SW_SHOW)

;Close button code here. Must-Have
;Others buttons use GUICtrlSetOnEvent(-1,"_function")
GUISetOnEvent($GUI_EVENT_CLOSE, "_mainexit")
GUISetOnEvent($GUI_EVENT_MINIMIZE, "_hide")

Func _mainexit()
	stopall()
	Exit
EndFunc   ;==>_mainexit

Func _hide()
	GUISetState(@SW_HIDE, $Form1)
EndFunc   ;==>_hide

Func _show()
	GUISetState(@SW_SHOWNORMAL, $Form1)
EndFunc   ;==>_show


;Add a Easy Log Function
Func Logger($text2log, $clearlog = 0)
	If $clearlog = 1 Then
		$hFile = FileOpen(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".log", 2)
		FileClose($hFile)
	EndIf
	If $text2log = "" Then Return
	If IsArray($text2log) Then
		For $arrayn = 0 To UBound($text2log) - 1
			;local $logtext = String($text2log[$arraynum])
			_FileWriteLog(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".log", String($text2log[$arrayn]))
			ConsoleWrite(String($text2log[$arrayn]) & @CRLF)
		Next
	Else
		_FileWriteLog(@ScriptDir & "\" & StringTrimRight(@ScriptName, 4) & ".log", String($text2log))
		ConsoleWrite(String($text2log) & @CRLF)
	EndIf
EndFunc   ;==>Logger

#EndRegion All Over-Head

;--------------------------Code Starts Here--------------------------
Global $hcaddy, $hphp, $hsql, $keepon

$keepon = 1

If ProcessExists("caddy.exe") Or ProcessExists("php-cgi.exe") Or ProcessExists("mysqld.exe") Then
	$killswitch = MsgBox(4, "Warning", "Some other caddy/php/mysql processes already exist. They may conflict. Do you want to restart them?", 10)
	If $killswitch = 6 Or $killswitch = -1 Then
		RunWait("taskkill /f /IM caddy.exe", @ScriptDir, @SW_HIDE)
		RunWait("taskkill /f /IM php-cgi.exe", @ScriptDir, @SW_HIDE)
		RunWait("taskkill /f /IM mysqld.exe", @ScriptDir, @SW_HIDE)
		Sleep(2000)
		RunWait(@ComSpec & ' /c taskkill /f /IM ' & @ScriptName & '&&start "" /D "' & @ScriptDir & '" "' & @ScriptFullPath & '"', '', @SW_HIDE)
	EndIf
EndIf

$sOutput = ""
Logger("Starting All Services...", 1)
startall()


;Sleep(1000)

;Logger("Caddy:" & StdoutRead($hcaddy))
;Logger("PHP:" & StdoutRead($hphp))
;Logger("MySQL:" & StdoutRead($hsql))

While 1
	$sOutput &= StderrRead($hcaddy)
	$sOutput &= StdoutRead($hcaddy)
	$sOutput &= StderrRead($hphp)
	$sOutput &= StdoutRead($hphp)
	$sOutput &= StderrRead($hsql)
	$sOutput &= StdoutRead($hsql)
	Logger($sOutput)
	$sOutput = ""

	If ProcessExists($hcaddy) Then
		GUICtrlSetBkColor($Label1, $COLOR_LIME)
	Else
		GUICtrlSetBkColor($Label1, $COLOR_RED)
		If $keepon = 1 Then
			startcaddy()
			Logger("Restarting Caddy")
			Sleep(10000)
		EndIf

	EndIf

	If ProcessExists($hphp) Then
		GUICtrlSetBkColor($Label2, $COLOR_LIME)
	Else
		GUICtrlSetBkColor($Label2, $COLOR_RED)
		If $keepon = 1 Then
			startphp()
			Logger("Restarting PHP")
			Sleep(10000)
		EndIf

	EndIf

	If ProcessExists($hsql) Then
		GUICtrlSetBkColor($Label3, $COLOR_LIME)
	Else
		GUICtrlSetBkColor($Label3, $COLOR_RED)
		If $keepon = 1 Then
			startsql()
			Logger("Restarting SQL")
			Sleep(10000)
		EndIf

	EndIf
	Sleep(1000)


WEnd


Func startcaddy()
	If ProcessExists($hcaddy) Then Return
	;If FileExists(@ScriptDir & "\caddy\envfile") = 0 Then FileWrite(@ScriptDir & "\caddy\envfile", "")
	;$hcaddy = Run(@ScriptDir & "\caddy\caddy.exe -email admin@mysite.com -envfile envfile -agree -disable-tls-alpn-challenge -quic", @ScriptDir & "\caddy", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	$hcaddy = Run(@ScriptDir & "\caddy\caddy.exe run", @ScriptDir & "\caddy", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	;$hcaddy = Run(@ComSpec & ' /c ' & '"' & @ScriptDir & '\caddy\caddy.exe' & '"' & ' run >> ' & @ScriptDir & '\caddy\caddylog.txt 2>&1', @ScriptDir & ' \caddy')
	;ConsoleWrite(@ComSpec & ' /c ' & '"' & @ScriptDir & '\caddy\caddy.exe' & '"' & ' run >> ' & @ScriptDir & '\caddy\caddylog.txt 2>&1' & @CRLF)
	;StdinWrite($iPID, "Banana" & @CRLF & "Elephant" & @CRLF & "Apple" & @CRLF & "Deer" & @CRLF & "Car" & @CRLF)
	;$sOutput &= StdoutRead($iPID)
EndFunc   ;==>startcaddy

Func stopcaddy()
	ProcessClose($hcaddy)
	$keepon = 0
EndFunc   ;==>stopcaddy

Func configcaddy()
	Local $fFilePath = @ScriptDir & '\caddy\Caddyfile'
	Run('Explorer /select,"' & $fFilePath & '"')
EndFunc   ;==>configcaddy


Func startphp()
	If ProcessExists($hphp) Then Return
	EnvSet("PHP_FCGI_CHILDREN", 4)
	EnvSet("PHP_FCGI_MAX_REQUESTS", 1000)
	$hphp = Run(@ScriptDir & "\php\php-cgi.exe -b localhost:9000", @ScriptDir & "\php", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
EndFunc   ;==>startphp

Func stopphp()
	RunWait(@ComSpec & " /c taskkill /F /PID " & $hphp & " /T", @SystemDir, @SW_HIDE)
	ProcessClose($hphp)
	$keepon = 0
EndFunc   ;==>stopphp

Func configphp()
	Local $fFilePath = @ScriptDir & '\php\php.ini'
	Run('Explorer /select,"' & $fFilePath & '"')
EndFunc   ;==>configphp

Func startsql()
	If ProcessExists($hsql) Then Return
	If FileExists(@ScriptDir & "\mysql\bin\mysql_install_db.exe") = 1 And FileExists(@ScriptDir & "\mysql\data\mysql") = 0 Then RunWait(@ScriptDir & "\mysql\bin\mysql_install_db.exe", @ScriptDir & "\mysql\bin", @SW_HIDE)
	$hsql = Run(@ScriptDir & "\mysql\bin\mysqld.exe --defaults-file=..\my.cnf --console", @ScriptDir & "\mysql\bin", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
EndFunc   ;==>startsql

Func Stopsql()
	ProcessClose($hsql)
	$keepon = 0
EndFunc   ;==>Stopsql

Func configsql()
	Local $fFilePath = @ScriptDir & '\mysql\my.cnf'
	Run('Explorer /select,"' & $fFilePath & '"')
EndFunc   ;==>configsql

Func startall()
	startcaddy()
	startphp()
	startsql()
	$keepon = 1
EndFunc   ;==>startall

Func stopall()
	stopcaddy()
	stopphp()
	Stopsql()
	$keepon = 0
EndFunc   ;==>stopall

Func openwww()
	Local $fFilePath = @ScriptDir & '\www'
	;Run('Explorer /select,"' & $fFilePath &'"')
	Run('Explorer "' & $fFilePath & '"')
EndFunc   ;==>openwww
