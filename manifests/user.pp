# @summary Add a user to an SFTP jail.
#
# @example Bob's home in the jail /chroot/myjail
#   sftp_jail::user {'bob':
#     jail => '/chroot/myjail',
#   }
#
# @example Bob's home and the group myjail_write has write access
#   sftp_jail::user{'bob':
#     group => 'myjail_write',
#     jail  => '/chroot/myjail',
#   }
#
# @param jail
#   Path to the jail that the user's directory should be set to.
#   Be careful not to add a trailing slash.
#   e.g. `/chroot/myjail`
#
# @param ensure
#   Ensure?
#
# @param user
#   The Users name.
#
# @param group
#   The users group.
#
# @param real_home
#   The real full path users home.
#
# @param sub_dirs
#   This directory structure is enforced in the users Home.
#
# @param merge_subdirs
#   Merge sub_dirs with the default sub_dirs?
#
define sftp_jail::user (
  Stdlib::Absolutepath      $jail,
  Enum['present', 'absent'] $ensure           = 'present',
  Accounts::User::Name      $user             = $name,
  Accounts::User::Name      $group            = $user,
  Stdlib::Absolutepath      $real_home        = "${jail}/home/${user}",
  Sftp_jail::Sub_dirs       $sub_dirs         = $sftp_jail::sub_dirs,
  Boolean                   $merge_subdirs    = false,
) {
  unless $ensure == 'absent' {
    if $ensure == 'absent' {
      $_ensure = 'absent'
    } else {
      $_ensure = 'directory'
    }

    unless $sub_dirs == $sftp_jail::sub_dirs {
      $merged_sub_dirs = $merge_subdirs ? {
        true    => unique($sftp_jail::sub_dirs + $sub_dirs),
        default => $sub_dirs,
      }
    } else {
      $merged_sub_dirs = $sub_dirs
    }
    $directories = [$real_home] + $merged_sub_dirs.map |$v| {
      "${real_home}/${v}"
    }
    file { $directories:
      ensure => $_ensure,
      owner  => $user,
      group  => $group,
      mode   => '0755',
    }
  }
}
