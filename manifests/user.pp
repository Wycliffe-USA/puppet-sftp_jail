# @summary Adds a user's home directory to an SFTP jail.
#
# Used for shared jails to allow multiple users to write, or to allow one user
# to write and others to read-only.
#
# @example Add user to the jail `myjail`
#   sftp_jail::user {'bob':
#     jail => '/chroot/myjail',
#   }
#
# @example Add user to the jail `myjail` and assign permissions
#   sftp_jail::user{'bob':
#     group => 'myjail_write',
#     jail  => '/chroot/myjail',
#   }
#
# @param user
#   The username that will own the corresponding home directory in the jail,
#   giving the user a place to land.
#
# @param group
#   The group that will own the corresponding home directory in the jail.
#
# @param jail
#   The path of the jail's base directory, such as `/chroot/myjail`. Do not
#   include a trailing slash.
#
define sftp_jail::user (
  $user  = $name,
  $group = $name,
  $jail =  undef,
) {
  file { "${jail}/home/${user}":
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0755',
  }
}
