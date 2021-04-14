# @example Single user
#   # The `sftp_jail::jail` resource creates a jail with a single home directory
#   # and an `incoming` directory. `incoming` is owned by the user and group
#   # provided when declaring the resource:
#   sftp_jail::jail { 'myjail':
#     user  => 'bbriggs',
#     group => 'bbriggs',
#   }
#
# @example Shared jail
#   # Sometimes, more than one user will need to access the same jail, but with
#   # different permissions. For instance, one may need read-write access while
#   # another is limited to read-only. In such a case, first create the jail with
#   # your write user and set up a match_group that redirects users. Again, the
#   # users and groups must already exist.
#   sftp_jail::jail { 'shared_jail':
#     user        => 'writeuser',
#     group       => 'writegroup',
#     match_group => 'sftpusers',
#   }
#   # Now add a user to your jail.
#   sftp_jail::user { 'readuser':
#     jail => '/chroot/shared_jail',
#   }
#   # To share write access to `/incoming`, set the `group` parameter of
#   # `sftp_jail::jail` to a group that is common to both users, such as the
#   # `sftpusers` group that you might use to redirect users into a jail.
#
# @param jail_name
#   The jails name.
#
# @param user
#   The user that will own the corresponding home directory in the jail, giving
#   the user a place to land. Also sets user ownership for `/incoming`.
#
# @param group
#   The group that will own the corresponding home directory in the jail,
#   giving the user a place to land. Also sets group ownership for `/incoming`.
#
# @param match_group
#   Set the group that SSHd will look for when redirecting users to the jail.
#   Useful for shared jails. Defaults to the value of `group`.
#
# @param password_authentication
#   OpenSSH Password Authentication
#
define sftp_jail::jail (
  $jail_name               = $name,
  $user                    = undef,
  $group                   = undef,
  $match_group             = undef,
  $password_authentication = 'no',
) {
  include sftp_jail
  $jail_base = "${sftp_jail::chroot_base}/${jail_name}"

  if ($match_group) {
    $ssh_match_group = $match_group
  }
  else {
    $ssh_match_group = $group
  }

  if !($group) {
    $group = $user
  }

  file { $jail_base:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$sftp_jail::chroot_base],
  }

  file { "${jail_base}/incoming":
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0775',
    require => File[$sftp_jail::chroot_base],
  }

  file { "${jail_base}/home":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$sftp_jail::chroot_base],
  }

  file { "${jail_base}/home/${user}":
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => File["${jail_base}/home"],
  }

  ssh::server::match_block { $ssh_match_group:
    type    => 'Group',
    options => {
      'ChrootDirectory'        => $jail_base,
      'ForceCommand'           => 'internal-sftp',
      'PasswordAuthentication' => $password_authentication,
      'AllowTcpForwarding'     => 'no',
      'X11Forwarding'          => 'no',
    },
  }
}
