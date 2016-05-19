Import-Module CanvasFunctions

### Set procedure variables
$table_name = "CANVAS_accounts"
$server_name = "SETON-SQL3"
$db_name = "canvas_sync"
$api_key = "3925~lTUMZwIlZTksziBGPfzcyWgFD107hHGqs6CInmD9HTqsoaPmEdCIHygBw13XeQ4j"

$headers = @{"Authorization"="Bearer "+$api_key}

### Initialize the SQL Text object array and then drop and create table
$accounts = @()
$accounts += "DROP TABLE " + $table_name + ";"
$accounts += "CREATE TABLE " + $table_name + "(
                            name nvarchar(255),
                            id nvarchar(255))"

$api_url_prefix = "https://setoncatholic.instructure.com/api/v1/accounts?per_page=100"
$results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
### Convert from JSON
$results = ConvertFrom-Json $results

### Create T-SQL statement to execute
foreach($r in $results)
{
    $scrubbed_name = $r.name -replace "'","''"
    $values = $scrubbed_name,$r.id
    $values_string = $values -join "','"
    $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
    $accounts += $rec_to_add
}

Add-APIData $server_name $db_name $accounts


