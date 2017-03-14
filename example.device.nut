#require "W5500.device.nut:1.0.0"


//================================================
// RUN
//================================================

function readyCb() {

    // Connection settings
    local destIP   = "192.168.1.42";
    local destPort = 4242;

    local started = hardware.millis();

    server.log("Attemping to connect...");
    server.log(server.log("isReady "+ wiz._isReady))
    wiz.configureNetworkSettings("192.168.1.2", "255.255.255.0", "192.168.1.1");
    wiz.openConnection(destIP, destPort, function(err, connection) {

        local dur = hardware.millis() - started;
        if (err) {
            server.error(format("Connection failed to %s:%d in %d ms: %s", destIP, destPort, dur, err.tostring()));
            imp.wakeup(30, function() {
                wiz.onReady(readyCb);
            })
            return;
        }

        server.log(format("Connection to %s:%d in %d ms", destIP, destPort, dur));

        // Create event handlers for this connection
        connection.onReceive(receiveCb);
        connection.onDisconnect(disconnectCb);

        // Send data over the connection
        local send;
        send = function() {
            server.log("Sending ...");
            connection.transmit("SOMETHING", function(err) {
                if (err) {
                    server.error("Send failed, closing: " + err);
                    connection.close();
                } else {
                    server.log(format("Sent successful to %s:%d", destIP, destPort));
                    imp.wakeup(10, send.bindenv(this));
                }
            }.bindenv(this));
        }
        send();

        // Receive the response
        connection.receive(function(err, data) {
            server.log(format("Manual response from %s:%d: " + data, this.getIP(), this.getPort()));
        })

    }.bindenv(this));

}

function receiveCb(err, response) {
    server.log(format("Catchall response from %s:%d: " + response, this.getIP(), this.getPort()));
}

function disconnectCb(err) {
    server.log(format("Disconnection from %s:%d", this.getIP(), this.getPort()));
    imp.wakeup(30, function() {
        wiz.onReady(readyCb);
    })
}


// Initialise SPI port
interruptPin <- hardware.pinXC;
resetPin     <- hardware.pinXA;
spiSpeed     <- 1000;
spi          <- hardware.spi0;
spi.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, spiSpeed);

started <- hardware.millis();

// Initialise Wiznet
wiz <- W5500(interruptPin, spi, null, resetPin);

// Wait for Wiznet to be ready before opening connections
server.log("Waiting for Wiznet to be ready ...");
wiz.onReady(readyCb);
