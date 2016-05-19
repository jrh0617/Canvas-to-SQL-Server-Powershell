Function Add-APIData ($server, $database, $text)
{
    $scon = New-Object System.Data.SqlClient.SqlConnection
    $scon.ConnectionString = "SERVER=$server;DATABASE=$database;Integrated Security=true"

    $cmd = New-Object System.Data.SqlClient.SqlCommand
    $cmd.Connection = $scon
    $cmd.CommandText = $text
    $cmd.CommandTimeout = 0

    $scon.Open()
    $cmd.ExecuteNonQuery()
    $scon.Close()
    $cmd.Dispose()
    $scon.Dispose()
}
