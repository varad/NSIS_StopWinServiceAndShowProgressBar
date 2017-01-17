!include "WinMessages.nsh"
!include "MUI2.nsh"
!include "nsDialogs.nsh"        
!include "NSIS_Service_Lib.nsh" ; External library: http://nsis.sourceforge.net/NSIS_Service_Lib

!insertmacro MUI_LANGUAGE "English"
 
OutFile "test.exe"
 
Section "EveryNsisScriptRequiresAtLeastOneSection"
SectionEnd


!define SERVICE_NAME "SnowMirror"        ; Name of the service to stop 
!define MAX_WAIT_TIME_MILLIS 90000       ; How long to wait for the service to stop
!define STOP_SERVICE_TIMER_INTERVAL 500  ; How often to check if the service has already stopped
Var StopService_MillisCounter            ; How long we have already waited for the service to stop
Var StopService_status                   ; Current state of the service
Var StopService_statusLabelHwnd          ; HWND of the label  
Var StopService_progressBarHwnd          ; HWND of the progress bar 

 
Page Custom page.custom
Function page.custom

  ; Create dialog. We have to pop the value from the stack
  nsDialogs::Create 1018
  Pop $0
 
  ; Create a label - x,y,width,height,text
	${NSD_CreateLabel} 0 0 100% 30 "Stopping ${SERVICE_NAME} service."
	Pop $StopService_statusLabelHwnd
 
  ; Create a progress bar - x,y,width,height,text
  ${NSD_CreateProgressBar} 0 30 100% 10% ""
  Pop $StopService_progressBarHwnd
  SendMessage $StopService_progressBarHwnd ${PBM_SETPOS} 0 0
  
  ; Reset the counter
  StrCpy $StopService_MillisCounter 1000
  
  ; Stop the service
  Call StopService_stop
  
  ; Repeatedly check service status and move the progress bar
  ${NSD_CreateTimer} StopServiceCallback ${STOP_SERVICE_TIMER_INTERVAL}
 
  ; Show GUI
  nsDialogs::Show
  
FunctionEnd 
 
;
; Checks a status of the service and sets the progress bar position.
; If it's done stopping the service it kills the timer so that it won't
; execute anymore. 
; 
Function StopServiceCallback

  Call StopService_getStatus
  
  ${If} $StopService_status == "stopped"
    SendMessage $StopService_statusLabelHwnd ${WM_SETTEXT} 0 "STR:Service ${SERVICE_NAME} has been successfully stopped."
    ${NSD_KillTimer} StopServiceCallback
  ${ElseIf} $StopService_MillisCounter >= ${MAX_WAIT_TIME_MILLIS}
    SendMessage $StopService_statusLabelHwnd ${WM_SETTEXT} 0 "STR:Failed to stop ${SERVICE_NAME} service."
    ${NSD_KillTimer} StopServiceCallback
  ${Else}
    IntOp $0 $StopService_MillisCounter / 1000
    IntOp $1 ${MAX_WAIT_TIME_MILLIS} / 1000
    SendMessage $StopService_statusLabelHwnd ${WM_SETTEXT} 0 "STR:Stopping ${SERVICE_NAME} service. $0s/$1s..."   
  ${EndIf}
  
  ${If} $StopService_status == "stopped"
    SendMessage $StopService_progressBarHwnd ${PBM_SETPOS} 100 0
  ${Else}
    IntOp $0 $StopService_MillisCounter * 100
    IntOp $0 $0 / ${MAX_WAIT_TIME_MILLIS}
    SendMessage $StopService_progressBarHwnd ${PBM_SETPOS} $0 0
  ${EndIf}
  IntOp $StopService_MillisCounter $StopService_MillisCounter + ${STOP_SERVICE_TIMER_INTERVAL}
  
FunctionEnd
 
;
; Loads a status of the service to $StopService_status
; 
Function StopService_getStatus
  Push "status"
  Push "${SERVICE_NAME}"
  Push ""
  Call Service
  Pop $StopService_status
FunctionEnd

;
; Stops the service.
;
Function StopService_stop
  Push "stop"
  Push "${SERVICE_NAME}"
  Push ""
  Call Service
FunctionEnd  