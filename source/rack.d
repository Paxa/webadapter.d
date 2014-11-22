module rack;

import core.thread;
import std.array;
import std.stdio;
import std.concurrency;

/*
void addShutdownHandler(void delegate() fn)
{
	handlers ~= fn;
	if (handlers.length == 1) // first
		register();
}
*/


class Rack {
    RackRunner[] threads;
    RackRequest[] requests;
    RackApp application;

    static RackAdapter delegate()[string] adapterFactories;

    static void registerAdapter(string name, RackAdapter delegate() fn) {
        adapterFactories[name] = fn;
    }

    static RackAdapter initServer(string name) {
        RackAdapter server;
        foreach(key, fn; adapterFactories) {
            if (key == name) {
                server = fn();
            }
        }
        return server;
    }

    this() {
        threads = [];
        for (int i = 0; i < 4; i += 1) {
            //threads ~= spawn(&processor);
            //threads ~= new RackRunner(this);
        }
        //start();
    }

    void start() {
        foreach (RackRunner thread; threads) {
            thread.start();
        }
    }

    void stop() {
        foreach (RackRunner thread; threads) {
            //thread.stop();
        }
    }

    void setApplication (RackApp app) {
        application = app;
    }

/*
    void processor () {
        receive(
            (int i) {
                writeln("Here we go.. ", i);
            }
        )
    }
*/

    void processRequest (RackRequest request) {
        writeln("Stored request");
        requests ~= request;
    }

    void call(RackRequest request) {
        writeln("Got request");
        application.call(request);
        //processRequest(request);
    }
}

interface RackAdapter {
    //this(Rack req_handler);
    //this();
    void setHandler(Rack handler);
    void setPort(int port);
    void start();
    void stop();
}

interface RackRequest {
    int write(string data);
    int addHeader(string header, string value);
    int setStatus(int status);
    string[][] getHeaders();
    string getHeader(string name);
    string requestMethod();
    string uri();
    string queryString();
}

/*
class RackThreadPool {
    Thread threads = [];
    int indicators = [];
    int min = 0;
    int max = 100;

    this(int _min, int _max) {
        min = _min;
        max = _max;
        for (int i = 0; i < min; i += 1) {
            threads[i] = new Thread;
        }
    }

    Thread borrow() {
        
    }
}
*/

class RackRunner : Thread {
    Rack rack;
    this(Rack new_rack) {
        rack = new_rack;
        super(&run);
    }

private :
    void run () {
        RackRequest req;
        writeln("Start polling ", getpid);
        writeln("Request ", rack);
        try {
            writeln("Request", rack.requests.length);
            while (true) {
                if (rack.requests.length > 0) {
                    writeln("Got request.");
                    req = rack.requests.front;
                    rack.requests.popFront();
                    rack.application.call(req);
                    req = null;
                    writeln("Request served.");
                } else {
                    Thread.sleep(dur!("msecs")(50));
                }
            }
        } catch (Exception e) {
            writeln("error happen");
        }
    }
}


class RackMiddleware {
    
}

interface RackApp {
    void call(RackRequest request);
}