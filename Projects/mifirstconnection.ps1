# Import the Veeam PowerShell module
Get-Module VeeamBackup

# Set the Veeam server connection information
$server = "veeamdaldir01.vmware-solutions.cloud.ibm.com"
$username = "fe_vcd_ldiaz"
$password = "8p4&g%tVu4g"

# Connect to the Veeam server
$sessieon = Connect-VBRServer -Server $server -Username $username -Password $password

# Get a list of all servers
$servers = Get-VeeamServer -Session $session

# For each server, get a list of all tasks
foreach ($server in $servers) {

    # Get a list of all tasks for the server
    $tasks = Get-VeeamTask -Server $server

    # Create a new Excel workbook
    $workbook = New-Object -TypeName Microsoft.Office.Interop.Excel.Workbook

    # Create a new sheet for each task
    foreach ($task in $tasks) {
        $sheet = $workbook.Worksheets.Add()
        $sheet.Name = $task.Name

        # Add the task information to the sheet
        $sheet.Range("A1").Value = "Nombre de la tarea"
        $sheet.Range("B1").Value = "Descripción de la tarea"
        $sheet.Range("C1").Value = "Fecha de inicio"
        $sheet.Range("D1").Value = "Fecha de finalización"

        $sheet.Range("A2").Value = $task.Name
        $sheet.Range("B2").Value = $task.Description
        $sheet.Range("C2").Value = $task.StartDateTime
        $sheet.Range("D2").Value = $task.EndDateTime
    }

    # Save the Excel workbook to a specific path
    $workbook.SaveAs("C:\Scripts\out\report.xlsx")

}

# Disconnect from the Veeam server
Disconnect-VeeamServer -Session $session