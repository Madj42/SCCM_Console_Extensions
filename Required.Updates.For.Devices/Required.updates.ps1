[CmdletBinding()]
param(
[parameter(Mandatory=$true)]
$SiteServer,
[parameter(Mandatory=$true)]
$RSRID
)

function Load-Form {
	$Form.Controls.Add($ResultsGrid)
    $Form.Add_Shown({Get-DeviceComplianceStatus})
	$Form.Add_Shown({$Form.Activate()})
	[void]$Form.ShowDialog()
}
# Get the Site Code
function Get-CMSiteCode {
    $CMSiteCode = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer | Select-Object -ExpandProperty SiteCode
    return $CMSiteCode
}

# Convert WMI Time
Function Get-NormalDateTime {
 	param(
    	$WMIDateTime
    )
	$NormalDateTime = [management.managementDateTimeConverter]::ToDateTime($WMIDateTime)
	return $NormalDateTime
}
# Get Device Update Compliance Status
function Get-DeviceComplianceStatus {
$Data=Get-WmiObject -computername $SiteServer -namespace root\SMS\site_$(Get-CMSiteCode) -Query "select distinct UCS.LocalizedDisplayName, SU.IsSuperseded,SU.IsExpired,SU.DatePostedfrom SMS_UpdateComplianceStatus UCS
join SMS_SoftwareUpdate SU on UCS.CI_ID=SU.CI_ID
join SMS_CIAllCategories cat on cat.CI_ID=UCS.CI_ID
where ucs.MachineID='$RSRID' and ucs.Status='2'"
#$results = @()
foreach ($update in $data)
{
$Title=$update.UCs.LocalizedDisplayName
$IsSuperseded=$update.SU.IsSuperseded
$IsExpired=$update.su.IsExpired
#$DatePosted=$update.SU.DatePosted
$DatePosted = Get-NormalDateTime $update.SU.DatePosted
$RowIndex = $ResultsGrid.Rows.Add($Title,$IsSuperseded,$IsExpired,$DatePosted)
		If($IsExpired -eq "True")
		 {
		   $ResultsGrid.Rows.Item($RowIndex).DefaultCellStyle.BackColor = "Red"
		 }
		If($IsSuperseded -eq "True")
		 {
		   $ResultsGrid.Rows.Item($RowIndex).DefaultCellStyle.BackColor = "Orange"
		 }
}
}

# Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Form
$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(900,470)  
$Form.MinimumSize = New-Object System.Drawing.Size(900,470)
$Form.MaximumSize = New-Object System.Drawing.Size(900,470)
$Form.SizeGripStyle = "Hide"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHome + "\powershell.exe")
$Form.Text = "Required Updates (www.eskonr.com)"
$Form.ControlBox = $true
$Form.TopMost = $true
#$Form.AutoSizeMode = "GrowAndShrink"
$Form.StartPosition = "CenterScreen"

# DataGriView
$ResultsGrid = New-Object System.Windows.Forms.DataGridView
$ResultsGrid.Location = New-Object System.Drawing.Size(20,30)
$ResultsGrid.Size = New-Object System.Drawing.Size(840,375)
$ResultsGrid.ColumnCount = 4
$ResultsGrid.ColumnHeadersVisible = $true
$ResultsGrid.Columns[0].Name = "Title"
$ResultsGrid.Columns[0].AutoSizeMode = "Fill"
$ResultsGrid.Columns[1].Name = "IsSuperseded"
$ResultsGrid.Columns[1].AutoSizeMode = "Fill"
$ResultsGrid.Columns[2].Name = "IsExpired"
$ResultsGrid.Columns[2].AutoSizeMode = "Fill"
$ResultsGrid.Columns[3].Name = "Date Posted"
$ResultsGrid.Columns[3].AutoSizeMode = "Fill"
$ResultsGrid.AllowUserToAddRows = $false
$ResultsGrid.AllowUserToDeleteRows = $false
$ResultsGrid.ReadOnly = $True
$ResultsGrid.ColumnHeadersHeightSizeMode = "DisableResizing"
$ResultsGrid.RowHeadersWidthSizeMode = "DisableResizing"

# Load form
Load-Form