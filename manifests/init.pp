# @summary Manage SFTP Jails
#
# @param chroot_base
#   All jails are located in this directory.
#
class sftp_jail (
  Stdlib::Absolutepath $chroot_base = '/chroot',
) {
  file { $chroot_base:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
