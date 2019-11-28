#!/usr/bin/expect

set package cloudagent.tar.gz
set path /home/cloudagent
set password openstack
set dmps [list 10.252.2.228 10.252.2.229 10.252.2.230 10.252.2.231]
set hosts [list 10.251.2.200 10.251.2.205 10.251.2.206 10.251.2.213 10.251.2.214]


proc make_path {user host password path} {
spawn ip netns exec trove_network ssh $user@$host
set timeout -1
expect {
	"yes/no" {
		send "yes\n"
		expect "password:"
		send "$password\n"
	}
	"password" {
		send "$password\n"
	}
}
expect "Last"
set timeout -1
send "

rm -rf $path
mkdir -p $path
exit 0
"
expect eof
}

proc scp_to_trove {user host password package path} {
spawn ip netns exec trove_network scp $package $user@$host:$path
set timeout -1
expect {
	"yes/no" {
		send "yes\n"
		expect "password:"
		send "$password\n"
	}
	"password" {
		send "$password\n"
	}
}
expect eof
}

proc deploy_package {user host password package path} {
spawn ip netns exec trove_network ssh $user@$host
set timeout -1
expect {
	"yes/no" {
		send "yes\n"
		expect "password:"
		send "$password\n"
	}
	"password" {
		send "$password\n"
	}
}
expect "Last"
set timeout -1
send "

cd $path
tar -zxvf $package
sh bin/install.sh
sleep 5s
exit 0
"
expect eof
}


foreach host $dmps { 
make_path root $host $password $path
scp_to_trove root $host $password $package $path
deploy_package root $host $password $package $path
puts "$host deploy success"
}


foreach host $hosts { 
make_path ubuntu $host $password $path
scp_to_trove ubuntu $host $password $package $path
deploy_package ubuntu $host $password $package $path
puts "$host deploy success"
}

