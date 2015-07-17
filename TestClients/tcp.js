/**
 * Created by Amershan on 2015. 07. 09..
 */
var net = require('net');
var readline = require('readline');
var  rl = readline.createInterface(process.stdin, process.stdout);
var client = new net.Socket();
var command='';

client.connect(9000, '127.0.0.1', function() {
    console.log('Connected');
    rl.setPrompt('KeyStore> ');
    rl.prompt();
});

rl.on('line', function(line) {
    var arrayOfStrings = line.split(' ');

    switch(arrayOfStrings[0]) {
        case 'help':
            console.log('Available commands: \n' +
                'store \n' +
                'Usage: store key value \n' +
                'getData \n' +
                'usage: getData key \n' +
                'Query a key from keystore \n ' +
                'getAllData \n' +
                'Usage: getAllData \n' +
                'Get all data in keystore \n' +
                'quit \n' +
                'Disconnects from the server and exit the app');
            break;
        case 'quit':
            client.write(line);
            process.exit(0);
            break;

        case 'store':
             if (arrayOfStrings.length != 3) {
                 console.log("wrong usage of the command store");
             } else {
                 client.write(arrayOfStrings[0] + ':::' + arrayOfStrings[1] + ':::' + arrayOfStrings[2]);
             }

            break;

        case 'getData':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command getData");
            } else {
                client.write(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
            }

            break;

        case 'getAllData':
            client.write(line);
            break;

        default:
            console.log('Wrong command');
            break;
    }
    rl.prompt();
}).on('close', function() {
    console.log('Have a great day!');
    process.exit(0);
});

client.on('data', function(data) {
    console.log('-> ' + data + '\n');
    //client.write('quit');
    //client.destroy(); // kill client after server's response
});

client.on('close', function() {
    console.log('Connection closed');
});
