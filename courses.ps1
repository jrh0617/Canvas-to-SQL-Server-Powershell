Import-Module CanvasFunctions

### Set procedure variables
$table_name = "CANVAS_courses"
$server_name = "SETON-SQL3"
$db_name = "canvas_sync"
$api_key = "3925~lTUMZwIlZTksziBGPfzcyWgFD107hHGqs6CInmD9HTqsoaPmEdCIHygBw13XeQ4j"
$first_sem_id = 5
$second_sem_id = 6

$pgnum=1
$headers = @{"Authorization"="Bearer "+$api_key}

### Initialize the SQL Text object array and then drop and create table
$add = @()
$add += "DROP TABLE " + $table_name + ";"
$add += "CREATE TABLE " + $table_name + "(
                            course_id nvarchar(255),
                            short_name nvarchar(255),
                            long_name nvarchar(255),
                            account_id nvarchar(255),
                            term_id nvarchar(255),
                            enrollment_term_id nvarchar(255),
                            id nvarchar(255))"

DO
{
    $another_page = $true

    ### Get records for page (first page if first time to run)

    if($another_page)
    { 
        $api_url_prefix = "https://setoncatholic.instructure.com/api/v1/accounts/self/courses?page=$pgnum&per_page=100&include=term"
        $results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
        ### Grab links header before changing from JSON. Used later in script
        $links = @()
        $links = $results.Headers.Link.ToString() -split ","

        ### Convert from JSON
        $results = ConvertFrom-Json $results

        ### Create T-SQL statement to execute
        foreach($r in $results)
        {
            $term_array = $r.term -split "; " -split "}"
            $pos=$term_array[5].IndexOf("sis_term_id=")+"sis_term_id=".Length
            $term = $term_array[5].SubString($pos)
            #Write-Host $term
            #$r.term.GetType()
            #if($r.term -is [system.array]){Write-Host "YES, it is an array"}
            #Else{Write-Host "NO, it is NOT an array"}
            if(($r.enrollment_term_id -eq $first_sem_id) -or ($r.enrollment_term_id -eq $second_sem_id))
            {
                $scrubbed_course_id = $r.sis_course_id -replace "'","''"
                $scrubbed_name = $r.name -replace "'","''"
                $values = $scrubbed_course_id,$r.course_code,$scrubbed_name,$r.account_id,$term,$r.enrollment_term_id,$r.id
                $values_string = $values -join "','"
                $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
                $add += $rec_to_add
            }
        }
    }

    $another_page = $false #set to false so that another page will set to true, otherwise will exit loop
    $link_urls = @()

    # this foreach checks to see if there is another page to pull3
    foreach($l in $links)
    {
        $url,$l = $l -split ";",2
        $l = $l.Trim()
        $link_urls += $url
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


