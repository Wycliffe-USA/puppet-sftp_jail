# @summary A list of sub directories
#
# @example A valid sub directory
#   As!8df/[1qwEr/zXcv0'
type Sftp_jail::Sub_Dirs = Array[Pattern[/\A([^\n\/\0]+\/*)*\z/]]
