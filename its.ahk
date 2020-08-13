/*
* Copyright(c) Jho. All right Reserved
* 2020.07.08
* its.ahk (AutoHotkey Script)
*/

;import SQL Module
#include MySQL.ahk

Gui, Add, Button, w200, Confirm
Gui, Add, Button, w200, Update
Gui, Show

;Critical Section
;if flag == 0 OK
;if flag != - Wait

global flag := false

;;info of DB
host := "127.0.0.1"
user := "root"
pw :="1q2w3e4r!"
database := "user"

;SQL start and connect
sql_start()

global myDB := dbConnect(Host, user, pw, database)
if(myDB = "error")
{
    MsgBox,% myDB
}

;Encoding usf8 for Korean
dbQuery(myDB,"set character set ecukr")

Return

;Get Data
ButtonConfirm:
{
    myQuery := "SELECT *FROM user WHERE list_id =='"arr[1]"';"
    
    result := dbQuery(myDB, myQuery)
    for index1, arr in result
    {
        myStr := "list_id : " . arr[1] . ", name : " . arr[2] . ", birth :" . arr[3] . ", its_flag :" . arr[4]
        _name := arr[2]
        _birth := arr[3]
        MsgBox % myStr
    }
}

Return

;Detect process On or OFF
IfWinExist, DurInfService
{
    WinActivate, 감염병 오염지역 방문자 조회 

}
IfWinNotExist, DurInfService
{
    Run C:\HIRA\HIRAINF\DurInfService.exe
    Sleep, 5000
    WinActivate, 감염병 오염지역 방문자 조회
}

/*
;요양기관 기호
ControlFocus, Edit1, 감염병 오염지역 방문자 조회
ControlSendRaw, Edit1, 37100548, 감염병 오염지역 방문자 조회

;의사면허번호
ControlFocus, Edit2, 감염병 오염지역 방문자 조회
ControlSendRaw, Edit2, 530866, 감염병 오염지역 방문자 조회
*/

;이름
ControlFocus, Edit4, 감염병 오염지역 방문자 조회
;ControlSend, Edit4, {BackSpace 6}, 감염병 오염지역 방문자 조회
;Sleep , 1000
ControlSendRaw, Edit4, %_name%, 감염병 오염지역 방문자 조회

;주민번호
ControlFocus, Edit5, 감염병 오염지역 방문자 조회
;ControlSend, Edit5, {BackSpace 13}, 감염병 오염지역 방문자 조회
;Sleep, 1000
ControlSendRaw, Edit5, %_birth%, 감염병 오염지역 방문자 조회

;인증서 호출 , 인증서 선택
ControlClick, Button11, 감염병 오염지역 방문자 조회
Sleep, 1000
WinActivate, 인증서 선택
ControlClick, Edit8 ;HardDIsk
Sleep, 1000

Try
{
    ControlClick, Edit1, 인증서 선택
    ControlFocus, Edit1, 인증서 선택
    Sleep, 1000
    ControlSendRaw, Edit1, !2whospital, 인증서 선택
    Sleep , 2000
    ControlSend, Edit1, {Enter}, 인증서 선택
    Sleep , 1000
}
catch {}

ControlGet, OutputVar, List, , SysListView321, 감염병 오염지역 방문자 조회
Sleep, 1000
IfInString, OutputVar, 비대상자
    flag := false
else
    flag := true

ControlClick, Button4,  감염병 오염지역 방문자 조회


;Update Data
ButtonUpdate:
{
    if(flag == true)
    {
        modifyQueryT := "UPDATE user SET ips_check_flag ='T' WHERE list_id ='"arr[1]"';"
    }
    else if(flag == false)
    {
        modifyQueryF := "UPDATE user SET ips_check_flag ='F' WHERE list_id ='"arr[1]"';"
    }
}

return 

GuiClose:
{
    dbDisConnect(myDB)
    exit_sql()
    ExitApp
}
return