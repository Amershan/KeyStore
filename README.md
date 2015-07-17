# KeyStore
Erlang memory based keystore

# MessageHub
In-memory MessageHub with support publish, subscribe, unsubscribe, create channel


#Install
```sh
$ git clone [git-repo-url]
$ cd KeyStore/src
$ erl --compile *.erl 
$ in erl terminal issue the following:
$ kaystore:start_server().
```
- Tcp server port: 9000
- Udp server port: 4000
- Http server port: 8080

# Test clients
There are node test clients in the repo.

#usage
```sh
$ cd Keystore/TestClients
$ node tcp
```
in a nother terminal 
```sh
$ cd MessageHub/TestClients
$ node udp
```
#Test client commands:
- store

 Usage: store key value  

- getData 

 Usage: getData key

- getAllData

 Usage: getAllData

- quit

 Usage: quit

#Note
If you are using your own client the server expects the commands in the following form:
command:::argument1:::argumentN
