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
user := "wujsol"
pw :="wujsol20)^@("
database := "wujsol"

;SQL start and connect
sql_start()

global myDB := dbConnect(Host, user, pw, database)
if(myDB = "error")
{
    MsgBox,% myDB
}

;Encoding usf8 for Korean
dbQuery(myDB,"set character set utf8")

Return

;Get Data
ButtonConfirm:
{
    myQuery := "SELECT *FROM user WHERE createtime > CURDATE() LIMIT 5;"
    
    result := dbQuery(myDB, myQuery)
    for index1, arr in result
    {
        myStr := "list_id : " . arr[1] . ", name : " . arr[3] . ", birth :" . arr[5] . ", its_flag :" . arr[12]
        _name := arr[2]
        _birth := arr[3]
        MsgBox % myStr
    }
}

Return

;Detect process On or OFF
IfWinExist, DurInfService
{
    WinActivate, ������ �������� �湮�� ��ȸ 

}
IfWinNotExist, DurInfService
{
    Run C:\HIRA\HIRAINF\DurInfService.exe
    Sleep, 5000
    WinActivate, ������ �������� �湮�� ��ȸ
}

/*
;����� ��ȣ
ControlFocus, Edit1, ������ �������� �湮�� ��ȸ
ControlSendRaw, Edit1, 37100548, ������ �������� �湮�� ��ȸ
;�ǻ�����ȣ
ControlFocus, Edit2, ������ �������� �湮�� ��ȸ
ControlSendRaw, Edit2, 530866, ������ �������� �湮�� ��ȸ
*/

;�̸�
ControlFocus, Edit4, ������ �������� �湮�� ��ȸ
;ControlSend, Edit4, {BackSpace 6}, ������ �������� �湮�� ��ȸ
;Sleep , 1000
ControlSendRaw, Edit4, %_name%, ������ �������� �湮�� ��ȸ

;�ֹι�ȣ
ControlFocus, Edit5, ������ �������� �湮�� ��ȸ
;ControlSend, Edit5, {BackSpace 13}, ������ �������� �湮�� ��ȸ
;Sleep, 1000
ControlSendRaw, Edit5, %_birth%, ������ �������� �湮�� ��ȸ

;������ ȣ�� , ������ ����
ControlClick, Button11, ������ �������� �湮�� ��ȸ
Sleep, 1000
WinActivate, ������ ����
ControlClick, Edit8 ;HardDIsk
Sleep, 1000

Try
{
    ControlClick, Edit1, ������ ����
    ControlFocus, Edit1, ������ ����
    Sleep, 1000
    ControlSendRaw, Edit1, !2whospital, ������ ����
    Sleep , 2000
    ControlSend, Edit1, {Enter}, ������ ����
    Sleep , 1000
}
catch {}

ControlGet, OutputVar, List, , SysListView321, ������ �������� �湮�� ��ȸ
Sleep, 1000
IfInString, OutputVar, ������
    flag := false
else
    flag := true 

ControlClick, Button4,  ������ �������� �湮�� ��ȸ


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