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
#   The jail name.
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
# @param groups
#   Additional groups the user should be in. Only useful for admins.
#
# @param  passowrd_hash
#   generate password hash with salt:
#     `python3 -c 'import crypt,getpass; print(crypt.crypt(getpass.getpass()))'`
#
# @param real_home
#   The real full path users home.
#
# @param home
#   The users $HOME environment variable.
#
# @param comment
#   Users comment / GECOS.
#
# @param manage_user
#   Manage the user resource?
#
# @param sftp_admin
#   Is this user an SFTP admin? SFTP Admins can read an probably write to user
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
  Sftp_jail::Groups         $groups                  = [],
  Optional[String[100]]     $password_hash           = undef,
  Stdlib::Absolutepath      $real_home               = "${jail_base}/home/${user}",
  Stdlib::Absolutepath      $home                    = "/home/${user}",
  Optional[String[2]]       $comment                 = undef,
  Boolean                   $manage_user             = false,
  Boolean                   $sftp_admin              = false,
  Sftp_jail::Sub_dirs       $sub_dirs                = $sftp_jail::sub_dirs,
  Boolean                   $merge_subdirs           = false,
  Boolean                   $purge                   = false,
  Accounts::User::Name      $match_group             = $group,
  Boolean                   $password_authentication = false,
) {
  include sftp_jail

  unless $sftp_admin or (($ensure == 'absent') and !$purge) {
    if $ensure == 'absent' {
      $_ensure = 'absent'
      $force = true
    } else {
      $_ensure = 'directory'
      $force = undef
    }
    file { default:
        ensure => $_ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        force  => $force,
      ;
      $jail_base: ;
      "${jail_base}/home":;
      "${jail_base}/incoming":
        owner => $user,
        group => $group,
        mode  => '0775',
      ;
    }
  }

  sftp_jail::user { $user:
    ensure        => $ensure,
    jail          => $jail_base,
    group         => $group,
    groups        => $groups,
    password_hash => $password_hash,
    real_home     => $real_home,
    home          => $home,
    comment       => $comment,
    manage_user   => $manage_user,
    sftp_admin    => $sftp_admin,
    sub_dirs      => $sub_dirs,
    merge_subdirs => $merge_subdirs,
    purge         => $purge,
  }

  if $ensure == 'present' {
    ssh::server::match_block { $match_group:
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
}
