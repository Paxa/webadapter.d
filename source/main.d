
import adapters.ae_http;
import adapters.mongoose;
import adapters.vibe;

import rack;

import webadapter.utils;

import std.string;
import std.getopt;

//import std.functional;

/*
extern(C) {
    int ev_handler(mg_connection *conn, mg_event ev) {
        int result = mg_result.MG_FALSE;

        if (ev == mg_event.MG_REQUEST) {
            mg_printf_data(conn, toCstring("Hello! Requested URI is [%s]"), conn.uri);
            result = mg_result.MG_TRUE;
        } else if (ev == mg_event.MG_AUTH) {
            result = mg_result.MG_TRUE;
        }

      return result;
    }
}
*/


class MyApp : RackApp {
    override void call(RackRequest request) {
        //writeln(request.getHeaders());

        writeln(request.getHeader("User-Agent"));

        writeln(request.requestMethod, " ", request.uri);
        writeln(request.queryString);

        request.addHeader("Content-Type", "application/json");
        request.setStatus(200);

        request.write("{ \"msg\": \"Bua!\" }");
    }
}

int main(string[] args) {

    Rack.registerAdapter("ae_http", {
        return new AeHttp();
    });

    Rack.registerAdapter("mongoose", {
        return new Mongoose();
    });

    Rack.registerAdapter("vibe", {
        return new VibeHttp();
    });

    string server_name = "vibe";
    getopt(args, "server",  &server_name);

    auto rack = new Rack();
    rack.setApplication(new MyApp);

    //auto server = Rack.initServer("ae_http")
    RackAdapter server;
    try {
        server = Rack.initServer(server_name);
    } catch (ArgumentError error) {
        puts("ERROR: ", error.msg);
        puts("Available: ", Rack.adapterFactories.keys.join(", "));
        return 1;
    }

    server.setHandler(rack);
    server.setPort(8080);
    writefln("Starting server '%s' at 127.0.0.1:8080", server_name);
    server.start();

    /*
    // future api:
    Rack.startServer("ae_http", rack, 8080);
    Rack.startServer("ae_http", new MyApp, 8080);
    Rack.startServer("ae_http", 8080, {
        return [200, [], "Content"];
    });
    */
  
  return 0;
}