
Import-Module CanvasFunctions

### Set procedure variables
$server_name = "SETON-SQL3"
$db_name = "canvas_sync"
$api_key = "3925~lTUMZwIlZTksziBGPfzcyWgFD107hHGqs6CInmD9HTqsoaPmEdCIHygBw13XeQ4j"
$headers = @{"Authorization"="Bearer "+$api_key}

### Grab all the courses from database. Put it into $courses
Import-Module -Name SQLPS -DisableNameChecking
$sections = Invoke-Sqlcmd -ServerInstance $server_name -database $db_name -query "select distinct id from CANVAS_sections"

### Initialize the SQL Text object array and then drop and create table
$enrollments = @()
$table_name = "CANVAS_enrollments"
$enrollments += "DROP TABLE " + $table_name + ";"
$enrollments += "CREATE TABLE $table_name (
                    sis_course_id nvarchar(255),
                    user_id nvarchar(255),
                    sis_user_id nvarchar(255),
                    role_id nvarchar(255),
                    sis_section_id nvarchar(255),
                    id nvarchar(255));"

foreach($id in $sections.id)
{
        $api_url_prefix = "https://setoncatholic.instructure.com/api/v1/sections/$id/enrollments?state=active&type=StudentEnrollment&per_page=1000"
        $results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
        ### Convert from JSON
        $results = ConvertFrom-Json $results
        Write-Host "id (section) = $id"

        ### Create T-SQL statement to execute
        foreach($r in $results)
        {
            if($r.sis_section_id -ne $null)
            {
                $scrubbed_sis_course_id = $r.sis_course_id -replace "'","''"
                $scrubbed_sis_section_id = $r.sis_section_id -replace "'","''"
                $values = $scrubbed_sis_course_id,$r.user_id,$r.user.sis_user_id,$r.role_id,$scrubbed_sis_section_id,$r.id
                $values_string = $values -join "','"
                $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
                $enrollments += $rec_to_add
            }
        }

        $api_url_prefix = "https://setoncatholic.instructure.com/api/v1/sections/$id/enrollments?state=active&type=TeacherEnrollment&per_page=1000"
        $results = (Invoke-WebRequest -Headers $headers -Method GET -Uri $api_url_prefix)
        
        ### Convert from JSON
        $results = ConvertFrom-Json $results

        ### Create T-SQL statement to execute
        foreach($r in $results)
        {
            if($r.sis_section_id -ne $null)
            {
                $scrubbed_sis_course_id = $r.sis_course_id -replace "'","''"
                $scrubbed_sis_section_id = $r.sis_section_id -replace "'","''"
                $values = $scrubbed_sis_course_id,$r.user_id,$r.user.sis_user_id,$r.role_id,$scrubbed_sis_section_id,$r.id
                $values_string = $values -join "','"
                $rec_to_add = "INSERT INTO " + $table_name + " VALUES ('" + $values_string + "')" + $nl
                $enrollments += $rec_to_add
            }
        }
}
        
Add-APIData $server_name $db_name $enrollments

<#
foreach($r in $enrollments)
    {
        Write-Host $r
    }
#>



