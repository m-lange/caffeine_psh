
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

    public bool DisplayRequired
    {
        get { return displayRequired; }
        set 
        { 
            displayRequired = value; 
            SetThreadExecutionState();
        }
    }

    public bool SystemRequired
    {
        get { return systemRequired; }
        set 
        { 
            systemRequired = value; 
            SetThreadExecutionState();
        }
    }

    public void JiggleMouse(object sender, EventArgs e)
    {
        if (displayRequired)
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
    }

    private void SetThreadExecutionState()
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


$Host.UI.RawUI.WindowTitle = "Caffeine"


$caffeine = [Caffeine]::new()

do {

    Clear-Host

    Write-Host
    Write-Host "Caffeine is running and preventing the system from entering sleep or turning off the display."
    Write-Host
    Write-Host "1:  [ $(@({' '},{'X'})[$caffeine.DisplayRequired]) ]  Prevent the system from turning off the display."
    Write-Host "2:  [ $(@({' '},{'X'})[$caffeine.SystemRequired]) ]  Prevent the system from entering sleep."
    Write-Host
    Write-Host
    Write-Host "Press 'Q' to quit . . . "

    $key = ([System.Console]::ReadKey($true)).Key

    switch ($key)
    {
        'D1'      { $caffeine.DisplayRequired = -not $caffeine.DisplayRequired }
        'NumPad1' { $caffeine.DisplayRequired = -not $caffeine.DisplayRequired }
        'D2'      { $caffeine.SystemRequired  = -not $caffeine.SystemRequired  }
        'NumPad2' { $caffeine.DisplayRequired = -not $caffeine.DisplayRequired }
        'Q'       { $caffeine.DisplayRequired = $caffeine.SystemRequired = $false }
    }

} while ($key -ne "Q")
