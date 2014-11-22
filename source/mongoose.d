module mongoose;

import std.string;
import std.stdio;
import core.thread;

import rack;
import mongoose_binding;

class Mongoose : RackAdapter {
    mg_server *server;
    mg_server*[] servers = [];
    Rack handler;
    void function(MongooseRequest) callback;
    static Mongoose instance;

    this(string name, void function(MongooseRequest) req_handler) {
        callback = req_handler;
        instance = this;
        server = mg_create_server(cast(void*)toCstring(name), &ev_handler);
    }

    this(Rack req_handler) {
        this();
        handler = req_handler;
    }

    this() {
        /*
        for(int i = 0; i < 4; i++) {
            servers ~= mg_create_server(cast(void*)handler, &ev_handler);
        }
        server = servers[0];
        */
    }

    void setHandler(Rack handler) {
        this.handler = handler;

        for(int i = 0; i < 4; i++) {
            servers ~= mg_create_server(cast(void*)handler, &ev_handler);
        }
        server = servers[0];
    }

    void setPort(int port) {
        mg_set_option(server, toCstring("listening_port"), toCstring(format("%d", port)));
    }

    void start () {
        if (servers.length) {
            foreach (mg_server* thread_server; servers) {
                if (thread_server != server) {
                    //mg_set_listening_socket(thred_server, mg_get_listening_socket(server));
                    mg_copy_listeners(server, thread_server);
                }
                auto c = cast(mg_thread_handler)&start_threaded;
                mg_start_thread(c, thread_server);

            }
        } else {
            for (;;) {
              mg_poll_server(server, 1000);
            }
        }
        Thread.sleep(50.seconds);
    }

    void stop () {
        mg_destroy_server(&server);
    }

    private static extern(C)
    void start_threaded(void* t_server) {
        writeln("Server started ");
        for (;;) mg_poll_server(cast(mg_server *)t_server, 1000);
    }

    private static extern(C)
    int ev_handler(mg_connection *conn, mg_event ev) {
        int result = mg_result.MG_FALSE;

        if (ev == mg_event.MG_REQUEST) {
            auto request = new MongooseRequest(conn);
            //writeln("server ", fromCstring(cast(cstring)conn.server_param));
            //writeln("Mongoose.instance ", Mongoose.instance);
            //writeln("Mongoose.instance rack ", Mongoose.instance.handler);
            Rack r = cast(Rack)conn.server_param;
            r.call(request);
            //Mongoose.instance.handler.call(request);
            result = mg_result.MG_TRUE;
        } else if (ev == mg_event.MG_AUTH) {
            result = mg_result.MG_TRUE;
        }

        return result;
    }
}

class MongooseRequest : RackRequest {
    mg_connection *conn;

    this(mg_connection *new_conn) {
        conn = new_conn;
    }

    override int write(string data) {
        mg_printf_data(conn, toCstring(data));
        return 1;
    }

    override int addHeader(string header, string value) {
        mg_send_header(conn, toCstring(header), toCstring(value));
        return 1;
    }

    override int setStatus(int status) {
        mg_send_status(conn, status);
        return 1;
    }

    string[][] getHeaders() {
        string[][] headers;
        headers.length = conn.num_headers;
        for (int i = 0; i < conn.num_headers; i++) {
            headers[i] = [conn.http_headers[i].name.fromCstring, conn.http_headers[i].value.fromCstring];
            //writefln("%s : %s", conn.http_headers[i].name.fromCstring, conn.http_headers[i].value.fromCstring);
        }
        return headers;
    }

    string getHeader(string name) {
        for (int i = 0; i < conn.num_headers; i++) {
            if (conn.http_headers[i].name.fromCstring == name) {
                return conn.http_headers[i].value.fromCstring;
            }
        }
        return null;
    }

    override string requestMethod() {
        return conn.request_method.fromCstring;
    }

    string uri() {
        return conn.uri.fromCstring;
    }

    string httpVersion() {
        return conn.http_version.fromCstring;
    }

    string queryString() {
        return conn.query_string.fromCstring;
    }

    string remoteIp() {
        return fromCstring(cast(const(ubyte)*)conn.remote_ip);
    }
}