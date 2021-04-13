# @summary sftp_jail class
#
# @param chroot_base
#   The directories path, which holds all jails.
#
# @param sftp_users
#   See `Sftp_jail::Sftp_Users` and `Sftp_jail::Sftp_User` types.
#
# @param manage_users
#   Should this module manage the user resources?
#
# @param sub_dirs
#   Default subdirectories to ensure in every users home. Can be overwritten for
#   each user seperatly.
#
# @param merge_subdirs
#   Merge sub_dirs with the default sub_dirs?
#
# @param admin_sub_dirs
#   Default subdirectories to ensure in every admins home. Can be overwritten for
#   each admin seperatly.
#
# @param pw_auth_users
#   Password Authentication setting for SFTP users.
#
# @param pw_auth_admins
#   Password Authentication setting for SFTP Admins.
#
class sftp_jail (
  Sftp_jail::Sftp_Users $sftp_users     = {},
  Stdlib::Absolutepath  $chroot_base    = '/chroot',
  Boolean               $manage_users   = false,
  Sftp_jail::Sub_dirs   $sub_dirs       = [],
  Boolean               $merge_subdirs  = false,
  Sftp_jail::Sub_dirs   $admin_sub_dirs = [],
  Boolean               $pw_auth_users  = false,
  Boolean               $pw_auth_admins = false,
) {
  $sftp_admins = $sftp_users.filter |$k, $v| { $v['sftp_admin'] }

  file { $chroot_base:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  unless $sftp_admins.empty {
    file { "${chroot_base}/home":
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    $sftp_user_groups = ($sftp_users - $sftp_admins).filter |$k, $v| {
      $v['ensure'] == 'present'
    }.map |$k, $v| {
      pick($v['group'], $k)
    }
  }

  $sftp_users.each |$k, $v| {
    if $v['sftp_admin'] {
      $jail_base = $chroot_base
      $options = {
        'sub_dirs' => $admin_sub_dirs,
        'merge_subdirs' => false,
        'password_authentication' => $pw_auth_admins,
      }
    } else {
      $jail_base = undef
      $options = {
        'sub_dirs' => $sub_dirs,
        'merge_subdirs' => $merge_subdirs,
        'password_authentication' => $pw_auth_users,
      }
    }

    sftp_jail::jail { $k:
        jail_base   => $jail_base,
        groups      => $sftp_user_groups,
        manage_user => $manage_users,
        *           => $options + $v,
    }
  }
}
