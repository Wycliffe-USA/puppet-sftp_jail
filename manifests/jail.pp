# @summary Jail for an SFTP user.
#
# @example Single user
#   sftp_jail::jail { 'myjail':
#     user  => 'bbriggs',
#     group => 'bbriggs',
#   }
#
# @example Shared jail
#   sftp_jail::jail { 'shared_jail':
#     user        => 'writeuser',
#     group       => 'writegroup',
#     match_group => 'sftpusers',
#   }
#
# @param jail_name
#   The jails name.
#
# @param jail_base
#   The jail's full path.
#
# @param user
#   The main user that will own the corresponding home directory in the jail,
#   giving the user a place to land. Also sets user ownership for `/incoming`.
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
# @param match_group
#   Set the group that SSHd will look for when redirecting users to the jail.
#   Useful for shared jails. Defaults to the value of group.
#
# @param password_authentication
#   Can the user login with a password? Public key authentication is generally
#   recommended and has to be configured outside of the scope of this module.
#
define sftp_jail::jail (
  Enum['present', 'absent'] $ensure                  = 'present',
  Sftp_jail::File_name      $jail_name               = $name,
  Stdlib::Absolutepath      $jail_base               = "${sftp_jail::chroot_base}/${jail_name}",
  Accounts::User::Name      $user                    = $name,
  Accounts::User::Name      $group                   = $user,
  Stdlib::Absolutepath      $real_home               = "${jail_base}/home/${user}",
  Sftp_jail::Sub_dirs       $sub_dirs                = $sftp_jail::sub_dirs,
  Boolean                   $merge_subdirs           = false,
  Accounts::User::Name      $match_group             = $group,
  Boolean                   $password_authentication = false,
) {
  include sftp_jail

  unless $ensure == 'absent' {
    file { [$jail_base, "${jail_base}/home"]:
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    file { "${jail_base}/incoming":
      ensure => 'directory',
      owner  => $user,
      group  => $group,
      mode   => '0775',
    }
  }

  sftp_jail::user { $user:
    ensure        => $ensure,
    jail          => $jail_base,
    group         => $group,
    real_home     => $real_home,
    sub_dirs      => $sub_dirs,
    merge_subdirs => $merge_subdirs,
  }

  ssh::server::match_block { $match_group:
    ensure  => $ensure,
    type    => 'Group',
    options => {
      'ChrootDirectory'        => $jail_base,
      'ForceCommand'           => 'internal-sftp',
      'PasswordAuthentication' => bool2str($password_authentication, 'yes', 'no'),
      'AllowTcpForwarding'     => 'no',
      'X11Forwarding'          => 'no',
    },
  }
}
