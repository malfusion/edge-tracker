# EdgeTrackr

A 2-tiered architecture for enhanced location tracking on the edge using 5G. It enables last-mile fine-grained tracking of personnel without overloading compute-heavy backend servers, by making use of lightweight edge servers to deal with and serve frequent location updates.

[![Alt text](https://img.youtube.com/vi/s8sT9H2RIsQ/0.jpg)](https://www.youtube.com/watch?v=s8sT9H2RIsQ&t=5s)


# To deploy
- Follow steps in aws-deployment-steps.sh

# To start Edge server
- `sudo apt update`
- `sudo apt install redis-server`
- `sudo nano /etc/redis/redis.conf`
- change `supervised no` -> `supervised systemd`
- `sudo systemctl restart redis.service`
- Git clone the project
- Serve the frontend from the `/client` directory
  - `python3 -m http.server`
- Start the nodejs websocket server from the `nodejs` directory
  - `node server.js`


# To start Backend Redis server
- Follow similar steps as edge to setup redis server
- Modify REDIS_EDGE_SERVER and REDIS_CORE_SERVER in `nodejs/edgetocore.js`
- Run `node edgetocore.js` to start streaming batched data from edge redis server to backend redis server.
