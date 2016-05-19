Import-Module CanvasFunctions

### Set procedure variables
$table_name = "CANVAS_users"
$server_name = "SETON-SQL3"
$db_name = "canvas_sync"
$api_key = "3925~lTUMZwIlZTksziBGPfzcyWgFD107hHGqs6CInmD9HTqsoaPmEdCIHygBw13XeQ4j"

$pgnum=1
$headers = @{"Authorization"="Bearer "+$api_key}

### Initialize the SQL Text object array and then drop and create table
$add = @()
$add += "DROP TABLE " + $table_name
$add += "CREATE TABLE $table_name (user_id nvarchar(255), login_id nvarchar(255), full_name nvarchar(255), id nvarchar(255))"

DO
{
    $another_page = $true

    ### Get records for page (first page if first time to run)

    if($another_page)
    { 
        $api_url_prefix = "https://setoncatholic.instructure.com/api/v1/accounts/self/users?page=$pgnum&per_page=100"
        $results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
        ### Grab links header before changing from JSON
        $links =@()
        $links = $results.Headers.Link -split ","

        ### Convert from JSON
        $results = ConvertFrom-Json $results

        ### Create T-SQL statement to execute
        foreach($r in $results)
        {
            $scrubbed_name = $r.name -replace "'","''"
            $values = $r.sis_user_id,$r.sis_login_id,$scrubbed_name,$r.id
            $values_string = $values -join "','"
            $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
            if($r.sis_user_id -ne $null) {$add += $rec_to_add} 
        }

    }

    $another_page = $false #set to false so that another page will set to true, otherwise will exit loop
    $link_urls = @()
    foreach($l in $links)
    {
        $url,$l = $l -split ";",2
        $l = $l.Trim()
        $link_urls += $url
        #Write-Host $l"`r`n"
        if($l -eq "rel=""next""")
        {
            $another_page = $true
            $pgnum++
        }
    }

} while($another_page)

<#
foreach($r in $add)
    {
        Write-Host $r
    }
#>

Add-APIData $server_name $db_name $add

