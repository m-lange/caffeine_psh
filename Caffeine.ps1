
Add-Type -TypeDefinition @"
using System;
using System.Timers;
using System.Runtime.InteropServices;

public class Caffeine
{
    private bool displayRequired = true;
    private bool systemRequired  = true;

    private Timer jiggle;

    public Caffeine()
    {
        SetThreadExecutionState();

        jiggle = new Timer();
        jiggle.Interval = 30000;
        jiggle.Elapsed += new ElapsedEventHandler(JiggleMouse);
        jiggle.Start();
    }

    public void JiggleMouse(object sender, EventArgs e)
    {
        INPUT input = new INPUT();
        input.type = 0;
        input.mi = new MOUSEINPUT();
        input.mi.dx = 0;
        input.mi.dy = 0;
        input.mi.mouseData = 0;
        input.mi.dwFlags = 0x0001;
        input.mi.time = 0;
        input.mi.dwExtraInfo = IntPtr.Zero;
        SendInput(1, new INPUT[] { input }, Marshal.SizeOf(input));
    }

    public void SetThreadExecutionState()
    {
        EXECUTION_STATE esFlags = EXECUTION_STATE.ES_CONTINUOUS;
        if (displayRequired) esFlags |= EXECUTION_STATE.ES_DISPLAY_REQUIRED;
        if (systemRequired)  esFlags |= EXECUTION_STATE.ES_SYSTEM_REQUIRED;

        SetThreadExecutionState(esFlags);
    }  

    [FlagsAttribute]
    public enum EXECUTION_STATE : uint
    {
        ES_AWAYMODE_REQUIRED = 0x00000040,
        ES_CONTINUOUS        = 0x80000000,
        ES_DISPLAY_REQUIRED  = 0x00000002,
        ES_SYSTEM_REQUIRED   = 0x00000001
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public uint mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT
    {
        public int type;
        public MOUSEINPUT mi;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern EXECUTION_STATE SetThreadExecutionState(EXECUTION_STATE esFlags);

    [DllImport("user32.dll", SetLastError = true)]
    static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);    
}
"@

[Caffeine]::new() | Out-Null


$Host.UI.RawUI.WindowTitle = "Caffeine"

do {

    Clear-Host
    Write-Host
    Write-Host "Caffeine is running and preventing the system from entering sleep or turning off the display.`r`n"
    Write-Host "Press 'Q' to quit . . . "

} while ( ([System.Console]::ReadKey($true)).Key -ne "Q" )
