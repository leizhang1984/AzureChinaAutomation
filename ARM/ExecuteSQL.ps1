<#
.PARAMETER SqlServer
    String name of the SQL Server to connect to

.PARAMETER SqlServerPort
    Integer port to connect to the SQL Server on

.PARAMETER Database
    String name of the SQL Server database to connect to

.PARAMETER TSQL
    T-SQL string need to execute

.PARAMETER SqlCredential
    PSCredential containing a username and password with access to the SQL Server  

.NOTES
    AUTHOR: Lei Zhang
    LASTEDIT: 2017-11-06
#>

workflow Use-SqlCommandSample
{
    param(
        [parameter(Mandatory=$True)]
        [string] $SqlServer="[servername].database.chinacloudapi.cn",
        
        [parameter(Mandatory=$False)]
        [int] $SqlServerPort = 1433,
        
        [parameter(Mandatory=$True)]
        [string] $Database="[DatabaseName]"
        
    )

    # Get the username and password from the SQL Credential
    $SqlUsername = "[AzureSQLDatabaseUserName]"
    $SqlPass = "[AzureSQLDatabasePassword]"
    
    inlinescript 
    {
        # Define the connection to the SQL Database
        $Conn = New-Object System.Data.SqlClient.SqlConnection
        $Conn.ConnectionString="Server=tcp:$using:SqlServer,$using:SqlServerPort;Database=$using:Database;User ID=$using:SqlUsername;Password=$using:SqlPass;Trusted_Connection=False;Encrypt=True;"
        # Open the SQL connection
        $Conn.Open()
        
        Write-Output "CONNECTION OPEN"

        # Define the SQL command to run. In this case we are getting the number of rows in the table
        $Cmd = New-Object System.Data.SqlClient.SqlCommand
        $Cmd.Connection = $Conn
        $Cmd.CommandTimeout=120
        
        $Cmd.CommandText = "TRUNCATE TABLE dbo.mytable"
        
        $Cmd.ExecuteNonQuery()
       
        # Close the SQL connection
        $Conn.Close()
        
        Write-Output "Execute T-SQL Successfully"
    }
}