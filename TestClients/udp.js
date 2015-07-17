/**
 * Created by Amershan on 2015. 07. 10..
 */
var PORT = 4000;
var HOST = '127.0.0.1';

var dgram = require('dgram');
var readline = require('readline');
var  rl = readline.createInterface(process.stdin, process.stdout);

var message = '';
var client = dgram.createSocket('udp4');

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
            message = new Buffer("quit");
            sendMessage(message);
            process.exit(0);
            break;

        case 'store':
            if (arrayOfStrings.length != 3) {
                console.log("wrong usage of the command store");
            } else {
                message = new Buffer(arrayOfStrings[0] + ':::' + arrayOfStrings[1] + ':::' + arrayOfStrings[2]);
                sendMessage(message);
            }

            break;

        case 'getData':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command getData");
            } else {
                message = new Buffer(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
                sendMessage(message);
            }

            break;

        case 'getAllData':
                message = new Buffer(line);
                sendMessage(message);
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

var sendMessage = function(message) {
    client.send(message, 0, message.length, PORT, HOST, function(err, bytes) {
        if (err) throw err;
        console.log('UDP message sent to ' + HOST +':'+ PORT);

    });

}

client.on('message', function (data) {
    console.log(data.toString() + "\n");

});
