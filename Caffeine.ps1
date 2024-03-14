
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
        SetThreadExecutionState();

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

$caffeine = [Caffeine]::new()


[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')    | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')          | Out-Null


$folder = Split-Path $MyInvocation.MyCommand.Path

 
$exit = New-Object System.Windows.Forms.ToolStripMenuItem
$exit.Text = "Exit"
$exit.add_Click( {
    $notifyIcon.Visible = $false
    Stop-Process $PID
})

$displayRequired = New-Object System.Windows.Forms.ToolStripMenuItem
$displayRequired.Text = "Prevent the system from turning off the display."
$displayRequired.Checked = $caffeine.DisplayRequired
$displayRequired.CheckState = [System.Windows.Forms.CheckState]::Checked
$displayRequired.add_Click( {
    $caffeine.DisplayRequired = -not $caffeine.DisplayRequired
    $displayRequired.Checked = $caffeine.DisplayRequired
})

$systemRequired = New-Object System.Windows.Forms.ToolStripMenuItem
$systemRequired.Text = "Prevent the system from entering sleep."
$systemRequired.Checked = $caffeine.SystemRequired
$systemRequired.CheckState = [System.Windows.Forms.CheckState]::Checked
$systemRequired.add_Click( {
    $caffeine.SystemRequired = -not $caffeine.SystemRequired
    $systemRequired.Checked = $caffeine.SystemRequired
})


$contextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip
$contextMenuStrip.Items.AddRange( @(
    $displayRequired,
    $systemRequired,
    (New-Object System.Windows.Forms.ToolStripSeparator),
    $exit
))


$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "Caffeine"
$notifyIcon.BalloonTipTitle = "Caffeine"
$notifyIcon.BalloonTipText = "Caffeine is running and preventing the system from entering sleep or turning off the display."
$notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$notifyIcon.Visible = $true
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$folder\Caffeine.ico")
$notifyIcon.ContextMenuStrip = $contextMenuStrip

$notifyIcon.ShowBalloonTip(5000);
      

$addTypeSplat = @{
    MemberDefinition = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    Name = "Win32ShowWindowAsync"
    Namespace = 'Win32Functions'
    PassThru = $true
}
$ShowWindowAsync = Add-Type @addTypeSplat

$null = $ShowWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 0)

[System.GC]::Collect()


$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)
