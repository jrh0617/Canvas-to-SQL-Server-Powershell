Import-Module CanvasFunctions

### Set procedure variables
$server_name = "SETON-SQL3"
$db_name = "canvas_sync"
$api_key = "3925~lTUMZwIlZTksziBGPfzcyWgFD107hHGqs6CInmD9HTqsoaPmEdCIHygBw13XeQ4j"
$pgnum=1
$headers = @{"Authorization"="Bearer "+$api_key}

### Grab all the courses from database. Put it into $courses
Import-Module -Name SQLPS -DisableNameChecking
$courses = Invoke-Sqlcmd -ServerInstance $server_name -database $db_name -query "select distinct id from CANVAS_courses"

### Initialize the SQL Text object array and then drop and create table
$sections = @()
$table_name = "CANVAS_sections"
$sections += "DROP TABLE " + $table_name + ";"
$sections += "CREATE TABLE $table_name (section_id nvarchar(255), course_id nvarchar(255), name nvarchar(255), id nvarchar(255))"

foreach($id in $courses.id)
{
        $api_url_prefix = "https://setoncatholic.instructure.com/api/v1/courses/$id/sections"
        $results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
        ### Convert from JSON
        $results = ConvertFrom-Json $results

        ### Create T-SQL statement to execute
        foreach($r in $results)
        {
            ### Write-Host "sis_course_id = "$r.sis_course_id
            if($r.sis_section_id -ne $null)
            {
                $scrubbed_course_id = $r.sis_course_id -replace "'","''"
                $scrubbed_section_id = $r.sis_section_id -replace "'","''"
                $scrubbed_name = $r.name -replace "'","''"
                $values = $scrubbed_section_id,$scrubbed_course_id,$scrubbed_name,$r.id
                $values_string = $values -join "','"
                $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
                $sections += $rec_to_add
            }
        }
}

Add-APIData $server_name $db_name $sections

<#       
foreach($r in $sections)
    {
        Write-Host $r
    }
Write-Host $server_name $nl $db_name

#>


