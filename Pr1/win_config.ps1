$users = Import-Csv -Delimiter : -Header Name,Group,Mail "users.csv"
$groups = Import-Csv -Delimiter : -Header Group "groups.csv"

# Array to store uper level groups to add read permission for lover grops
$uper_groups = @()
foreach($group in $groups)
{
    New-LocalGroup -Name $group.Group
    $group_folder = "C:\ALL_GROUPS\$($group.Group)"
    New-Item -Path $group_folder -ItemType Directory

    $acl = Get-Acl $group_folder
    $new_acl = New-Object System.Security.AccessControl.FileSystemAccessRule($group.Group,'Read','ContainerInherit, ObjectInherit','InheritOnly','Allow')
    $acl.AddAccessRule($new_acl)
    $acl | Set-Acl $group_folder

    foreach($uper_group in $uper_groups)
    {
        $acl = Get-Acl $group_folder
        $new_acl = New-Object System.Security.AccessControl.FileSystemAccessRule($uper_group,'Read','ContainerInherit, ObjectInherit','InheritOnly','Allow')
        $acl.AddAccessRule($new_acl)
        $acl | Set-Acl $group_folder
    }

    $uper_groups += $group.Group
    
}


foreach($user in $users)
{
    "Adding user $($user.Name) with group $($user.Group). One-time pass is $($user.Mail)"
    # Using one-time password from email(for more secure we can generate it and store somehow)
    $password = convertto-securestring $user.Mail -AsPlainText -Force
    New-LocalUser $user.Name -Password $password
    # Force user to cahnge password after login
    Set-LocalUser -Name $user.Name -PasswordNeverExpires $false

    $user_folder = "C:\ALL_GROUPS\$($user.Group)\$($user.Name)"

    New-Item -Path $user_folder -ItemType Directory

    $acl = Get-Acl $user_folder
    $new_acl = New-Object System.Security.AccessControl.FileSystemAccessRule($user.Name,'FullControl','ContainerInherit, ObjectInherit','InheritOnly','Allow')
    $acl.AddAccessRule($new_acl)
    $acl | Set-Acl $user_folder

    if($user.Group -eq "CEO") {
        # Adding SEO to Administrators group so he can have full permissions for everything
        "Adding user $($user.Name) to Administrators"
        Add-LocalGroupMember -Group "Administrators" -Member $user.Name
    }
    
}

# Public folder for every user created by script
New-Item -Path "C:\ALL_GROUPS\Public" -ItemType Directory

# Setting write permissions to CEO folder for Managers8
$acl = Get-Acl "C:\ALL_GROUPS\CEO"
$new_acl = New-Object System.Security.AccessControl.FileSystemAccessRule('Managers','WriteData','ContainerInherit, ObjectInherit','InheritOnly','Allow')
$acl.AddAccessRule($new_acl)
$acl | Set-Acl "C:\ALL_GROUPS\CEO"

# Adding Supreme full right to Managers
$acl = Get-Acl "C:\ALL_GROUPS\Managers"
$new_acl = New-Object System.Security.AccessControl.FileSystemAccessRule('Supreme','FullControl','ContainerInherit, ObjectInherit','InheritOnly','Allow')
$acl.AddAccessRule($new_acl)
$acl | Set-Acl "C:\ALL_GROUPS\Managers"
