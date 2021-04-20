# @param sftp_users
#   See `Sftp_jail::Sftp_Users` and `Sftp_jail::Sftp_User` types.
#
# @param chroot_base
#   The directories path, which holds all jails.
#
# @param sub_dirs
#   Default subdirectories to ensure in every users home. Can be overwritten for
#   each user seperatly.
#
# @param merge_subdirs
#   Merge sub_dirs with the default sub_dirs?
#
# @param pw_auth_users
#   Password Authentication setting for SFTP users.
#
class sftp_jail (
  Sftp_jail::Sftp_Users $sftp_users     = {},
  Stdlib::Absolutepath  $chroot_base    = '/chroot',
  Sftp_jail::Sub_dirs   $sub_dirs       = [],
  Boolean               $merge_subdirs  = false,
  Boolean               $pw_auth_users  = false,
) {
  file { $chroot_base:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  $sftp_users.each |$k, $v| {
    $options = {
      'sub_dirs' => $sub_dirs,
      'merge_subdirs' => $merge_subdirs,
      'password_authentication' => $pw_auth_users,
    }

    sftp_jail::jail { $k:
      * => $options + $v,
    }
  }
}
