Import-Module CanvasFunctions

### Set procedure variables
$table_name = "CANVAS_terms"
$server_name = "SETON-SQL3"
$db_name = "canvas_sync"
$api_key = "3925~lTUMZwIlZTksziBGPfzcyWgFD107hHGqs6CInmD9HTqsoaPmEdCIHygBw13XeQ4j"
$headers = @{"Authorization"="Bearer "+$api_key}
$account = 1

### Initialize the SQL Text object array and then drop and create table
$terms = @()
$terms += "DROP TABLE " + $table_name + ";"
$terms += "CREATE TABLE " + $table_name + "(
                            name nvarchar(255),
                            sis_term_id nvarchar(255),
                            account_id nvarchaR(255),
                            id nvarchar(255))"

$api_url_prefix = "https://setoncatholic.instructure.com/api/v1/accounts/$account/terms?per_page=100"
$results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
### Convert from JSON
$results = ConvertFrom-Json $results

### Create T-SQL statement to execute
foreach($r in $results.enrollment_terms)
{
    $scrubbed_name = $r.name -replace "'","''"
    $scrubbed_sis_term_id = $r.sis_term_id -replace "'","''"
    $values = $scrubbed_name,$r.sis_term_id,$account,$r.id
    $values_string = $values -join "','"
    $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
    $terms += $rec_to_add
}

Add-APIData $server_name $db_name $terms


