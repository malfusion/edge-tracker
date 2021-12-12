const redis = require('redis');
georedis = require('georedis')
// Configuration: adapt to your environment
const REDIS_CORE_SERVER = "redis://localhost:6379/1";
const REDIS_EDGE_SERVER = "redis://localhost:6379/0";

var coreClient = redis.createClient(REDIS_CORE_SERVER);
var edgeClient = redis.createClient(REDIS_EDGE_SERVER);
var geo;

coreClient.on('error', (err) => console.log('Redis Core Client Error', err));
edgeClient.on('error', (err) => console.log('Redis Edge Client Error', err));

var prev = undefined;
var current = {};
const flushInterval = 2000;

async function flush() {
    prev = current;
    current = {}
    console.log(prev);
    geo.addLocations(prev, function(err, reply){
        if(err) console.error(err)
        else console.log('Pushed locations to core... ', reply)
    })
    setTimeout(flush, flushInterval);
}

async function start() {
    // await coreClient.connect();
    // await edgeClient.connect();

    setTimeout(flush, flushInterval);
    console.log("Connected to both redis server")
    edgeClient.subscribe('loc_updates', (error, count) => {
        console.log(error);    
    });
    edgeClient.on("message", (channel, message) => {
            // console.log(message, channel);
            message =  JSON.parse(message);
            current[message[2]] = {latitude: message[0], longitude: message[1]}
            // console.log(Object.keys(current).length)
      });
}

coreClient.on("connect", () => {
    console.log('coreClient connect redis success !')
    edgeClient.on("connect", () => {
        console.log('edgeClient connect redis success !')
        geo = georedis.initialize(coreClient);
        start()
       })
   })


