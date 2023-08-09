function ConvertTo-DataTable
{
<#
.EXAMPLE
$DataTable = ConvertTo-DataTable $Source
.PARAMETER Source
An array that needs converting to a DataTable object
#>
    [CmdLetBinding(DefaultParameterSetName="None")]
    param(
    [Parameter(Position=0,Mandatory=$true)][System.Array]$Source,
    [Parameter(Position=1,ParameterSetName='Like')]$Match=".+",
    [Parameter(Position=2,ParameterSetName='NotLike')]$NotMatch=".+"
    )
    if ($NotMatch -eq ".+"){
        $Columns = $Source[0] | Select * | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -match "($Match)"}
    }
    else {
        $Columns = $Source[0] | Select * | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -notmatch "($NotMatch)"}
    }

    $DataTable = New-Object System.Data.DataTable
    foreach($Column in $Columns.Name) {
        $DataTable.Columns.Add("$($Column)") | Out-Null
    }
    #For each row (entry) in source, build row and add to DataTable
    foreach ($Entry in $Source) {
        $Row = $DataTable.NewRow()
        foreach ($Column in $Columns.Name){
            $Row["$($Column)"] = if($Entry.$Column -ne $null){($Entry | Select-Object -ExpandProperty $Column) -join ', '}else{$null}
        }
        $DataTable.Rows.Add($Row)
    }
    #Validate source column and row Count to DataTable
    if ($Columns.Count -ne $DataTable.Columns.Count){
        throw "Conversion failed: Number of columns in source does not match datatable number of columns"
    }
    else{
        if ($Source.Count -ne $DataTable.Rows.Count){
            throw "Conversion failed: Source row count not equal to datatable row count"
        }
        #The use of "Return ," ensure the output from function is of the same datatype, otherwise it's returned as an array
        else{
            Return ,$DataTable
        }
    }
}

function SendTo-Database([System.Data.SqlClient.SqlCommand] $command)
{
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $password = (-join("P`@$","$","w0rd"))
    $sqlConnection.ConnectionString = "Server=DESKTOP-VPOQODT;Database=NewDatabase;UID=app;Password=" + $password

    try
    {
        $sqlConnection.Open()

        $command.Connection = $sqlConnection
        $command.CommandTimeout = 30
        $command.ExecuteNonQuery() | Out-Null
    }
    catch [Exception]
    {
        Write-Warning $_.Exception.Message
    }
    finally
    {
        $sqlConnection.Close()
    }
}

$measurements = @(
    @{Measurement="V - PoSH";Value="22"},
    @{Measurement="W - PoSH";Value="23"},
    @{Measurement="X - PoSH";Value="24"},
    @{Measurement="Y - PoSH";Value="25"},
    @{Measurement="Z - PoSH";Value="26"}) | % { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }


$measurements.GetType()
$measurements | Out-GridView

$dt_measurements = ConvertTo-DataTable($measurements)

$dt_measurements.GetType()
$dt_measurements | Out-GridView

$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.CommandType = [System.Data.CommandType]::StoredProcedure
$cmd.CommandText = "dbo.usp_Measurements_Upsert"
$cmd.Parameters.AddWithValue("@LocationCode", 7) | Out-Null
$cmd.Parameters.AddWithValue("@dt_Measurements", $dt_measurements) | Out-Null

SendTo-Database($cmd)
