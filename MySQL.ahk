;============================================================
; mysql.ahk
;   re-made by elderlykim
;   update date : 2018.11.29.
;   Provides a set of functions to connect and query a mysql database
;============================================================

;============================================================
; The fileinstall command does 2 things.
; 1. When this ahk program is compiled into an exe, fileinstall indicates which files should be embedded inside the exe.
; 2. When the exe version of the program is run, fileinstall extracts the embedded file to the specified folder.
; 
; note: #include files are automatically embedded at compile time, so you don't need to use fileinstall for them.
;============================================================ 

;FileInstall, libmysql.dll, %A_AppData%\libmysql.dll, 1

;============================================================
; Connect to mysql database and return db handle
;
; host = DTWRO-WS0061	
; user = alan
; password = reddog
; database = rush
;============================================================ 

sql_start()
{
    global hModule, db
    ExternDir := A_ScriptDir

	hModule := DllCall("LoadLibrary", "Str", ExternDir "\libmysql.dll")
		
	If (hModule = 0)
	{
		MsgBox 16, mysql Error 233, Can't load libmysql.dll from directory %ExternDir%
		ExitApp
	}

	db := DllCall("libmysql.dll\mysql_init", "ptr", 0)
			
	If (db = 0)
	{
		MsgBox 16, mysql Error 445, Not enough memory to connect to MySQL
		ExitApp
	}
}


dbConnect(host,user,password,database, port := ""){
	global thishost, thisuser, thispassword, thisdatabase, db
	
	thishost := host
	thisuser := user
	thispassword := password
	thisdatabase := database
    
	connection := DllCall("libmySQL.dll\mysql_real_connect"
         , "ptr", db
         , "Astr", host       ; host name
         , "Astr", user       ; user name
         , "Astr", password   ; password
         , "Astr", database   ; database name
         , "UInt", port   ; port
         , "UInt", 0   ; unix_socket
         , "UInt", 0)   ; client_flag

	If (connection = 0)
	{
        MsgBox, Cannot connect to database
	    ;HandleMySQLError(db, "Cannot connect to database")
		Return "error"
	}

	; serverVersion := DllCall("libmySQL.dll\mysql_get_server_info", "ptr", db, "AStr")
	; MsgBox % "Ping database: " . DllCall("libmysql.dll\mysql_ping", "UInt", db) . "`nServer version: " . serverVersion

	return db

}

;============================================================
; mysql error handling
;============================================================ 

HandleMySQLError(db, message, query="", ByRef errorCode = "", ByRef errorStr = "") {		; the equal sign means optional
   errorCode := DllCall("libmysql.dll\mysql_errno", "Uint", db)
   errorStr := DllCall("libmysql.dll\mysql_error", "Uint", db, "Astr")
   ;MsgBox 16, mysql Error: %message%, Error %errorCode%: %errorStr%`n`n%query%
	Return 
}

;============================================================
; mysql get address
;============================================================ 

GetUIntAtAddress(_addr, _offset)
{
   return NumGet(_addr+0,_offset * 4, "uint")
}

GetPtrAtAddress(_addr, _offset)
{
   return NumGet(_addr+0,_offset * A_PtrSize, "ptr")
}

;============================================================
; process query
;============================================================ 

dbQuery(ByRef _db, _query, errmsg=1)
{
   local resultString, result, requestResult, fieldCount
   local row, lengths, length, fieldPointer, field

	query4error := RegExReplace(_query , "\t", "   ")	; convert tabs to spaces so error message formatting is legible
   result := DllCall("libmysql.dll\mysql_query", "Uint", _db , "Astr", _query)
			
   If (result != 0) {
	  errorMsg = %_query%
	  errorcde := DllCall("libmySQL.dll\mysql_errno", "UInt", db)
            if (errorcde = 2003) or (errorcde = 2006) or (errorcde = 0) {     ; sql connection lost (2003) or sql connection timeout (2006)
                ; attempt sql reconnect
                _db := dbConnect(thishost,thisuser,thispassword,thisdatabase)   ; reconnect to mysql database
                    
                If (_db = "") {   ; reconnect failed
                    thiserror := 2006
                    thiserrstr := "MySQL server unavailable"
                    if errmsg
                        msgbox, 16, % "MySQL Error: " thiserror , % thiserrstr "`n`n" _query 
                    Return
						}
                }
		HandleMySQLError(_db, "dbQuery Fail", query4error, errorCode, errorStr)
        errorResult := ["error", errorCode, errorStr]
		Return errorResult
   }
	
   requestResult := DllCall("libmysql.dll\mysql_store_result", "ptr", _db)
	
	if (requestResult = 0) {	; call must have been an insert or delete ... a select would return results to pass back
		return
	}
	
	fieldCount := DllCall("libmysql.dll\mysql_num_fields", "ptr", requestResult)
    
    resultArray := []
    row_index := 0
    Loop
    {
        row_index++
        row := DllCall("libmysql.dll\mysql_fetch_row", "ptr", requestResult)
        If (row = 0 || row == "")
            Break
        
        rowArray := []
        ; Get a pointer on a table of lengths (unsigned long)
        lengths := DllCall("libmysql.dll\mysql_fetch_lengths" , "ptr", requestResult)

        Loop %fieldCount%
        {
            length := GetUIntAtAddress(lengths, A_Index - 1)
            fieldPointer := GetPtrAtAddress(row, A_Index - 1)
            field := StrGet(fieldPointer, length, "CP0")            
            rowArray[A_index] := field            
        }   
        resultArray[row_index] := rowArray
    } 	
	
   Return resultArray
}

errorCheck(resultArr)
{
    if(resultArr[1] = "error")
    {
        return true
    }
    else
    {
        return false
    }
}

dbDisConnect(ByRef db)
{
    DllCall("libmysql.dll\mysql_close", "ptr", db)    
}

exit_sql()
{
    global hModule
    DllCall("FreeLibrary","ptr",hModule)
}

escape_string(unescaped_string)
    {
        escaped_string := RegExReplace(unescaped_string, "\\", "\\")     ; \
        escaped_string := RegExReplace(escaped_string, "'", "\'")        ; '
        
        escaped_string := RegExReplace(escaped_string, "`t", "\t")       ; \t
        escaped_string := RegExReplace(escaped_string, "`n", "\n")       ; \n
        escaped_string := RegExReplace(escaped_string, "`r", "\r")       ; \r
        escaped_string := RegExReplace(escaped_string, "`b", "\b")       ; \b
        
        ; these characters appear to insert fine in mysql    
        ;escaped_string := RegExReplace(escaped_string, "%", "\%")        ; %
        ;escaped_string := RegExReplace(escaped_string, "_", "\_")        ; _
        ;escaped_string := RegExReplace(escaped_string, """", "\""")      ; "
        
        return escaped_string
    }
/*
lvfill(sql, result, listviewname, selectmode=0)
    {
    
        ;-------------------------------------------
        ; delete all rows in listview
        ;-------------------------------------------
    
        GuiControl, -Redraw, %listviewname%     ; to improve performance, turn off redraw then turn back on at end
        
        Gui, ListView, %listviewname%    ; specify which listview will be updated with LV commands  
        
        if (selectmode = 1) {
            column1value := ""
            selectedrow := LV_GetNext(0)     ; get current selected row
            if selectedrow |= 0
                LV_GetText(column1value, selectedrow, 1) ; get column 1 value for current row          
        } else if (selectmode = 2) {
            selectedrow := LV_GetNext(0)     ; get current selected row
        }
        
        LV_Delete()  ; delete all rows in listview
        
        ;-------------------------------------------
        ; delete all pre-existing columns (must delete in reverse order because it is a shifting target)
        ;-------------------------------------------

        columncount := LV_GetCount("Column")

        if columncount > 0
            Loop, %columncount%
            {	
                LV_DeleteCol(columncount)
                columncount--
                if columncount = 0
                    break
            }
        
        ;-------------------------------------------
        ; create columns
        ;-------------------------------------------

        columns := sqlcolumns(sql)    ; get list of column names in comma delimited list
        
        totalcolumns := 0
        iconcolumn := 0
        Loop, parse, columns, CSV
        {	
            totalcolumns++
            
            ;colname := RegExReplace(A_LoopField, "\$", "")
            ;LV_DeleteCol(A_Index)   already deleted above
            
            LV_InsertCol(A_Index,"",A_LoopField)   ; create column with name from sql, but remove possible $ which indicates a hidden field
            
            if (A_LoopField = "icon$" ) {  ; detect optional icon column 
                iconcolumn := A_Index    ; save icon column number for later
                ; create imagelist for icons
                ImageListID := IL_Create(10)  ; Create an ImageList to hold small icons, this list can grow, so 10 is ok
                LV_SetImageList(ImageListID)  ; Assign the above ImageList to the current ListView.
                VarSetCapacity(Filename, 260)   ; Ensure the variable has enough capacity to hold the longest file path.
                sfi_size = 352
                VarSetCapacity(sfi, sfi_size)   ; This is done because ExtractAssociatedIconA() needs to be able to store a new filename in it.
            }
        }
        
        ;-------------------------------------------
        ; fileinstall brokenlink.ico to represent missing files in icon file list
        ;-------------------------------------------
        
        if (iconcolumn != 0) {
            RegExMatch(A_ScriptName, "^(.*?)\.", basename) 
            if Not InStr(FileExist(A_AppData "\" basename1), "D")    ; create appdata folder if doesnt exist
                FileCreateDir , % A_AppData "\" basename1

            file := "brokenlink.ico"
            brokenlink = %A_AppData%\%basename1%\brokenlink.ico  
            
            If FileExist( "./brokenlink.ico" ) {  ; if brokenlink.ico exists then install in appdata
                FileInstall, brokenlink.ico, %brokenlink%, 0   ; 0=no overwrite, 1=overwrite
            }
        }
        
        ;-------------------------------------------
        ; using first row values, set integer columns
        ;-------------------------------------------
        
        StringGetPos, pos, result, `n   ; extract first row from result
        StringLeft, row, result, pos
        Loop, parse, row, |
        {	
            StringReplace, data, A_LoopField, % " KB",,   ; remove " KB" so that column can be interpreted as an integer
            if data is integer
                LV_ModifyCol(A_Index, "Integer")  ; For sorting purposes, indicate column is an integer.
        }

        ;-------------------------------------------
        ; parse rows
        ;-------------------------------------------
        
        count := 0
        Loop, parse, result, `n
        {		
            
            IfEqual, A_LoopField, , Continue  ; Ignore blank rows (usually last row)

            LV_Add("") ; add blank row to listview
            
            StringSplit, array, A_LoopField, |      ; extract columns
            
            ; if icon column exists then use given path to create icon for current row
            if (iconcolumn != 0) {   
            
                iconpath := array%iconcolumn%     ; get column text
                
                ; Get the high-quality small-icon associated with this file extension:
                if DllCall("Shell32\SHGetFileInfoA", "str", iconpath, "uint", 0, "str", sfi, "uint", sfi_size, "uint", 0x101)  ; 0x101 is SHGFI_ICON+SHGFI_SMALLICON
                {
                    ; Extract the hIcon member from the structure:
                    hIcon = 0
                    Loop 4
                        hIcon += *(&sfi + A_Index-1) << 8*(A_Index-1)
                    ; Add the HICON directly to the small-icon and large-icon lists.
                    ; Below uses +1 to convert the returned index from zero-based to one-based:
                    IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID, "int", -1, "uint", hIcon) + 1
                    DllCall("DestroyIcon", "uint", hIcon)   ; Now that it's been copied into the ImageLists, the original should be destroyed
                } else {
                    if DllCall("Shell32\SHGetFileInfoA", "str", brokenlink, "uint", 0, "str", sfi, "uint", sfi_size, "uint", 0x101)  ; 0x101 is SHGFI_ICON+SHGFI_SMALLICON
                    {
                        ; Extract the hIcon member from the structure:
                        hIcon = 0
                        Loop 4
                            hIcon += *(&sfi + A_Index-1) << 8*(A_Index-1)
                        ; Add the HICON directly to the small-icon and large-icon lists.
                        ; Below uses +1 to convert the returned index from zero-based to one-based:
                        IconNumber := DllCall("ImageList_ReplaceIcon", "uint", ImageListID, "int", -1, "uint", hIcon) + 1
                        DllCall("DestroyIcon", "uint", hIcon)   ; Now that it's been copied into the ImageLists, the original should be destroyed                
                    } else {
                        IconNumber := 9999999  ; Set it out of bounds to display a blank icon.
                    }
                }
                
                LV_Modify(A_Index, "Icon" . IconNumber)   ; set row icon             
            }
            
            row := A_Index
            
            ; populate columns of current row
            Loop, parse, columns, CSV     
            {
                data = col%A_index%      ; trick to indicate colx in following LV_Modify command
                LV_Modify(row,data,array%A_Index%)      ; update current column of current row
            }
                    
        }
        
        ;-------------------------------------------
        ; autosize columns: should be done outside the row loop to improve performance
        ;-------------------------------------------
        
        LV_ModifyCol()  ; Auto-size each column to fit its contents.
        Loop, parse, columns, CSV
        {	
            if (A_Index != totalcolumns)     ; do all except last column
                LV_ModifyCol(A_Index,"AutoHdr")   ; Autosize header.
            
            if RegExMatch(A_LoopField, "\$$")    ;If there is a $ at end of column name, that indicates a hidden column
                LV_ModifyCol(A_Index,0)   ; set width to 0 to create hidden column
            
        }
        
        ;LV_ModifyCol(2,0)    ; makes column 0 width... therefore, hidden
        
        Gui, Submit, NoHide               ; update v control variables	

        ; re-select logic

        if (selectmode = 1) {    ;reselect row by column1value
            if (column1value != "") {
                Loop % LV_GetCount()   ; loop through all rows in listview to find column1value
                {
                    LV_GetText(value, A_Index, 1)    ; get column1 value for current row

                    If (value = column1value) {
                        LV_Modify(A_Index, "+Select +Focus")     ; select originally selected row in list  
                        break
                    }
                }
            }
        } else if (selectmode = 2) {    ; reselect row by row number
            if (selectedrow != 0)
                LV_Modify(selectedrow, "+Select +Focus")     ; select originally selected row in list   
        }
        
        GuiControl, +Redraw, %listviewname%     ; to improve performance, turn off redraw at beginning then turn back on at end
        
        Return

    }

    ;============================================================ 
    ; lvread
    ; gets the contents of a listview and returns in result form (columns are | delimited and rows are `n delimited)
    ;============================================================ 

    lvread(listviewname)
    {
        Gui, ListView, %listviewname%    ; specify which listview will be updated with LV commands  
    
        result := ""
        
        Loop % LV_GetCount()   ; loop through all rows in listview 
        {
            row := A_Index

            Loop % LV_GetCount("Column")    ; loop through all columns
            {
                LV_GetText(value, row, A_Index)    ; get column value
            
                result .= value "|"  
            }
            
            result .= "`n"
        }
        
        return result
    }    
        
    ;============================================================
    ; extract column names from sql string and return in a comma delimited list
    ;============================================================ 

    sqlcolumns(sql)
    {
        sql := RegExReplace(sql , "\n", " ")    ; collapse multiline string ... replace \n with spaces
        sql := RegExReplace(sql , "\t", " ")    ; replace \t with space
        sql := RegExReplace(sql , "\s+", " ")   ; collapse multiple spaces to single space replace \s+ with " "
        sql := RegExReplace(sql , "\([^\(]+?\)", "")   ; remove parenthetical items because they may contain commas... 	
        sql := RegExReplace(sql , "\([^\(]+?\)", "")   ; run a second time to account for parens inside parens
        sql := RegExReplace(sql , "\([^\(]+?\)", "")   ; run a third time to account for parens inside parens (this will handle 3 levels deep for parens)
        
        if (RegExMatch(sql, "i)SELECT (.*?) FROM ", data) )     ; extract substring using regex and store subpatterns (.*) into data1, data2...etc
            selectclause := data1     
        else
            return sql     ; data does not contain select clause, so it may already be a comma delimited list
        

        columns := ""
        Loop, Parse, selectclause , CSV 
        {

            if A_LoopField =     ; skip blanks
                continue 
            
            item := RegExReplace(A_LoopField , "^\s+", "")    ; remove beginning spaces
            item := RegExReplace(item , "\s+$", "")           ; remove ending spaces
            
            ; find possible alias
            if (RegExMatch(item, "i).* as (.*)", alias)) { ; extract substring using regex and store subpatterns (.*) into data1, data2...etc
                aliasname := RegExReplace(alias1 , "_", " ")   ; replace possible underscores with spaces in aliasname
                columns = %columns%%aliasname%,
            } else {
                columns = %columns%%item%,
            }
            
        }
            
        ; remove last comma delimiter    
        columns := RegExReplace(columns , ",$", "") 

        return columns
    }

    ;============================================================
    ; return the text for a given columnName and row number
    ; Same as LV_GetText, except columnname can be given instead of column number
    ;============================================================

    lv_gettext2(ByRef OutputVar, RowNumber, ColumnName)
    {
        ; Find ColumnNumber for given ColumnName
        
        Loop % LV_GetCount("Column")
        {
            LV_GetText(name, 0, A_Index)  ; get column name  
            
            If (Name = ColumnName) {
                ; A_Index is the columnnumber
                LV_GetText(OutputVar, RowNumber, A_Index)
                return
            }
        }
        
        return 
    }