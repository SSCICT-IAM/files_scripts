#!/usr/bin/perl
# Variables

$backupdir = "__REPLACE__";
$username = "__REPLACE__";
$password = "__REPLACE__";

# Determine current day
$day = `/bin/date +'%a'`;
chomp($day);

# Remove old backups if exists
if ( -e "$backupdir/mongo-dump-$day/") {
  `rm -f $backupdir/mongo-dump-$day/*`;
}

# Dump databases
`mongodump --username $username --password $password --host "manage/database-node.example.org:27017" --authenticationDatabase admin --out $backupdir/mongo-dump-$day`;

# Gzip dumps
opendir(BDIR, "$backupdir/mongo-dump-$day/");
my @files = readdir(BDIR);
closedir(BDIR);
chdir("$backupdir/mongo-dump-$day/");
foreach $dir (@files) {
  if ($dir !~ /^\.+$/) {
    if ($dir !~ /\.\./g) {
      if ( -d "$backupdir/mongo-dump-$day/$dir") {
        `tar -cvzf $backupdir/mongo-dump-$day/$dir.tar.gz $dir/`;
        `rm -rf $backupdir/mongo-dump-$day/$dir/`;
      }
    }
  }
}
