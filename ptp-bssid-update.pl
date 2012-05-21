#!/usr/bin/perl

#use strict;
use Socket;

my ($cookie,$query,@date,$datestr,$port,$iaddr,$paddr,$proto,$line);

# To use this script, discover your own auth cookie and sid and include customized expressions as commented out below:
#$cookie='phpbb2mysql_data=a%3A2%3A%7Bs%3A11%3A%22autologinid%22%3Bs%3A0%3A%22%22%3Bs%3A6%3A%22userid%22%3Bi%3A-1%3B%7D; auth=$YOURUSERNAME%3A786538655%3A1187426809%3AIAe%2FsXTUPOUb0C7sEpZYHw';
#phpbb2mysql_sid=$32characterHexString

$query = "POST /gps/gps/main/confirmquery/ HTTP/1.1
Host: wigle.net
Accept: text/plain
Keep-Alive: 300
Connection: keep-alive
Cookie: $cookie
Content-Type: application/x-www-form-urlencoded";

@date = localtime;

$datestr = sprintf("%04d%02d%02d-%02d%02d%02d",
                   $date[5]+1900,$date[4]+1,$date[3],$date[2],$date[1],$date[0]);

open(CACHE,">/tmp/ptp-bssid-update-html-$datestr") or die "open: $!";
open(RESULT,">ptp-bssid-update-download-$datestr") or die "open: $!";

$proto = getprotobyname('tcp');
$port = getservbyname('http', 'tcp');
$iaddr = inet_aton("wigle.net");

$paddr = sockaddr_in($port,$iaddr);

# query www.personaltelco

print "debug: query www.personaltelco\n";

socket(SOCK,PF_INET,SOCK_STREAM,$proto) or die "socket: $!";
connect(SOCK,$paddr) or die "connect: $!";
select(SOCK); $| = 1; select(STDOUT); # turns on autoflush for SOCK
print SOCK <<EOF;
$query
Content-Length: 34

ssid=www.personaltelco&Query=Query
EOF

shutdown(SOCK, 1);
while (<SOCK>) {
    print CACHE $_;
    if (/^<td>/) {
        s|</td><td>|\t|g;
        s|<td>||;
        s|</td></tr>||;
        s|&nbsp;||g;
        print RESULT $_;
        chomp;
        ($netid,$network) = split /\t/, $_, 2;
        $netid =~ tr/a-z/A-Z/;
        $data{$netid} = $network;
    }
}
close(SOCK);


print "debug: query personaltelco\n";

# query personaltelco
socket(SOCK,PF_INET,SOCK_STREAM,$proto) or die "socket: $!";
connect(SOCK,$paddr) or die "connect: $!";
select(SOCK); $| = 1; select(STDOUT); # turns on autoflush for SOCK
print SOCK <<EOF;
$query
Content-Length: 30

ssid=personaltelco&Query=Query
EOF

shutdown(SOCK, 1);
while (<SOCK>) {
    print CACHE $_;
    if (/^<td>/) {
        s|</td><td>|\t|g;
        s|<td>||;
        s|</td></tr>||;
        s|&nbsp;||g;
        print RESULT $_;
        chomp;
        ($netid,$network) = split /\t/, $_, 2;
        $netid =~ tr/a-z/A-Z/;
        $data{$netid} = $network;
    }
}
close(SOCK);

open(OLD,"ptp-bssid-with-notes") or die "open: $!";

while(<OLD>) {
    chomp;
    ($bssid,@old) = split /\t/;
    $bssid =~ tr/a-z/A-Z/;
    $note{$bssid} = $old[$#old];
    if (! defined($data{$bssid})) {
        # if no new data yet, query by bssid

        print "debug: querying $bssid with $note{$bssid}";

        socket(SOCK,PF_INET,SOCK_STREAM,$proto) or die "socket: $!";
        connect(SOCK,$paddr) or die "connect: $!";
        select(SOCK); $| = 1; select(STDOUT); # turns on autoflush for SOCK
        print SOCK <<EOF;
$query
Content-Length: 35

netid=$bssid&Query=Query
EOF

        shutdown(SOCK, 1);
        while (<SOCK>) {
            print CACHE $_;
            if (/^<td>/) {
                s|</td><td>|\t|g;
                s|<td>||;
                s|</td></tr>||;
                s|&nbsp;||g;
                print RESULT $_;
                chomp;
                ($netid,$network) = split /\t/, $_, 2;
                $netid =~ tr/a-z/A-Z/;
                $data{$netid} = $network;
            }
        }
        close(SOCK);
    }
}

foreach $key (keys %data) { $merged{$key}++; }

foreach $key (keys %note) { $merged{$key}++; }

foreach $key (sort keys %merged) {
    print join "\t", $key, $data{$key}, $note{$key};
    print "\n";
}

close(CACHE);

exit;
