const WebSocket = require('ws');
const redis = require('redis');

// Configuration: adapt to your environment
const REDIS_SERVER = "redis://localhost:6379/0";
const WEB_SOCKET_PORT = 3000;

// Connect to Redis and subscribe to "app:notifications" channel
var redisClient = redis.createClient(REDIS_SERVER);
var redisPubClient = redis.createClient(REDIS_SERVER);
var sends = 0;

redisClient.on('error', (err) => console.log('Redis Client Error', err));

redisClient.on("connect", () => {
  console.log('redisClient connect redis success !')

  redisPubClient.on("connect", () => {
    console.log('redisPubClient connect redis success !')

    // Create & Start the WebSocket server
    const server = new WebSocket.Server({ port: WEB_SOCKET_PORT });
    redisClient.subscribe('loc_updates', (error, count) => {
      console.log(error);    
    });
    // Register event for client connection
    server.on('connection', (ws) => {
      console.log("Connected to a client")
      ws.on('message', (msg) => {
        redisPubClient.publish('loc_updates', msg);
      });
      var redisListener = (channel, message) => {
        if (sends % 1000 == 0) console.log(sends)
        sends+=1
        ws.send(message);
      };
      // broadcast on web socket when receving a Redis PUB/SUB Event
      redisClient.on("message", redisListener);
      ws.on("close", () => { console.log("client disconnected"); redisClient.removeListener("message", redisListener); });

      // redisClient.subscribe('loc_updates', (message, channel) => {
        
      // });
    });
    console.log("WebSocket server started at ws://localhost:" + WEB_SOCKET_PORT);

  });
  
  
});
  

