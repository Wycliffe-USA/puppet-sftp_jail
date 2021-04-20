# @summary An SFTP User
#
# @param group
#   The group that will own the corresponding home directory in the jail,
#   giving the user a place to land. Also sets group ownership for /incoming.
#
# @param sub_dirs
#   This directory structure is enforced in the users Home.
#
# @param merge_subdirs
#   Merge sub_dirs with the default sub_dirs?
#
# @param ensure
#   Ensure the user?
#
# @param purge
#   Delete the users home and all it's content, if the user is set to 'absent'.
#
# @param jail_name
#   Multi user SFTP jail this user belongs to (read more at sftp_jail::jail).
#
type Sftp_jail::Sftp_User = Struct[{
  Optional[group]         => Accounts::User::Name,
  Optional[sub_dirs]      => Sftp_jail::Sub_Dirs,
  Optional[merge_subdirs] => Boolean,
  Optional[ensure]        => Enum['present', 'absent'],
  Optional[purge]         => Boolean,
  Optional[jail_name]     => Sftp_jail::File_name,
}]
