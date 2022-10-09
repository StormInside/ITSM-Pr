#!/bin/bash
apt update
apt install acl 

# Array to store uper level groups to add read permission for lover grops
higher_groups=()
while IFS=":" read -r rec_column1
do
  group_name=${rec_column1::-1}
  echo "Creating group $group_name"
  groupadd -f $group_name
  mkdir /home/$group_name
  chgrp $group_name /home/$group_name
  for value in "${higher_groups[@]}"
  do
      # r-x to have possibility to cd to folder
      echo "Adding r-x for $value"
      setfacl -Rdm g:$value:r-x /home/$group_name
  done
  higher_groups+=($group_name)
done < <(tail -n +1 groups.csv)

# Public folder for every user created by script
groupadd -f Public
mkdir /home/Public
chmod 770 /home/Public
chgrp Public /home/Public


while IFS=":" read -r rec_column1 rec_column2 rec_column3
do
  username=$rec_column1
  group_name=$rec_column2
  email=${rec_column3::-1}

  echo "Adding user $username with group $group_name. One-time pass is $email"

  useradd -b /home/$group_name -m -g $group_name -N $username 
  # Using one-time password from email(for more secure we can generate it and store somehow)
  echo $username:$email | chpasswd
  # Force user to cahnge password after login
  passwd --expire $username 
  # rwx:r--:--- permissions for every file created in this folder
  umask 0740 /home/$rec_column2/$username

  usermod -aG Public $username

  if [ $group_name == "SEO" ]; then
    # Adding SEO to sudo group so he can have full permissions for everything
    usermod -aG sudo $username
  else
    # Prohibiting some commads for all users exept SEO
    file_location=$(which interface)
    setfacl -m u:$username:--- $file_location
    file_location=$(which kill)
    setfacl -m u:$username:--- $file_location
    file_location=$(which apt)
    setfacl -m u:$username:--- $file_location
  fi
  if [ $group_name == "Supreme" ]; then
    # Adding Supreme full right to Administration and Managers
    setfacl -Rdm g:$group_name:rwx /home/Administration
    setfacl -Rdm g:$group_name:rwx /home/Managers
  fi
  
done < <(tail -n +1 users.csv)

# Setting write permissions to CEO folder for Managers
setfacl -Rdm g:Managers:-w- /home/CEO

# Setting password policy without additional tools
cp ./common-password-min-12 /etc/pam.d/common-password