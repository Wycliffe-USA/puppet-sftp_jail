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
# @param groups
#   Additional groups the user should be in. Only usefull for admins.
#
# @param real_home
#   The real full path users home.
#
# @param home
#   The users $HOME environment variable.
#
# @param  passowrd_hash
#   generate password hash with salt:
#     `python3 -c 'import crypt,getpass; print(crypt.crypt(getpass.getpass()))'`
#
# @param comment
#   Users comment / GECOS.
#
# @param manage_user
#   Manage the user resource?
#
# @param sftp_admin
#   Is this user an SFTP admin? SFTP Admins can read an probaply write to user
#   Data.
#
# @param sub_dirs
#   This directory structure is enforced in the users Home.
#
# @param merge_subdirs
#   Merge sub_dirs with the default sub_dirs?
#
# @param purge
#   Delete the users home and all it's content, if the user is set to 'absent'.
#
define sftp_jail::user (
  Stdlib::Absolutepath  $jail,
  Enum['present', 'absent'] $ensure           = 'present',
  Accounts::User::Name      $user             = $name,
  Accounts::User::Name      $group            = $user,
  Sftp_jail::Groups         $groups           = [],
  Optional[String[100]]     $password_hash    = undef,
  Stdlib::Absolutepath      $real_home        = "${jail}/home/${user}",
  Stdlib::Absolutepath      $home             = "/home/${user}",
  Optional[String[2]]       $comment          = undef,
  Boolean                   $manage_user      = false,
  Boolean                   $sftp_admin       = false,
  Sftp_jail::Sub_dirs       $sub_dirs         = $sftp_jail::sub_dirs,
  Boolean                   $merge_subdirs    = false,
  Boolean                   $purge            = false,
) {
  unless ($ensure == 'absent') and !$purge {
    if $ensure == 'absent' {
      $_ensure = 'absent'
      $force = true
    } else {
      $_ensure = 'directory'
      $force = undef
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
      force  => $force,
    }
  }

  if $manage_user {
    $full_comment= "${comment} SFTP only ${bool2str($sftp_admin, 'admin', 'user')}"

    accounts::user { $user:
      ensure     => $ensure,
      comment    => $full_comment,
      group      => $group,
      groups     => $groups,
      home       => $home,
      locked     => true,
      managehome => false,
      membership => 'inclusive',
      password   => $password_hash,
    }
  }
}
