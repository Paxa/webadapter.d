module adapters.ae_http;

import ae.net.http.server;
import ae.net.http.common;
import ae.net.asockets;
import ae.net.shutdown;
import ae.sys.data;

import rack;

import std.traits;
import std.stdio;

class AeHttp : RackAdapter {
    Rack handler;
    HttpServer ae_server;

    this() {
        ae_server = new HttpServer();
        ae_server.handleRequest = &onRequest;
    }

    this(Rack req_handler) {
        this();
        handler = req_handler;
    }

    void setHandler(Rack handler) {
        this.handler = handler;
    }

    void setPort(int port) {
        //addShutdownHandler({ ae_server.close(); });
        ae_server.listen(cast(ushort)port, "127.0.0.1");
    }

    void start () {
        socketManager.loop();
    }

    void stop () {
        ae_server.close();
    }

    void onRequest(HttpRequest request, HttpServerConnection conn) {
        auto req = new AeHttpRequest(request, conn);
        handler.call(req);
        req.setContentData();
        conn.sendResponse(req.response);
    }
}

class AeHttpRequest : RackRequest {
    HttpRequest ae_req;
    HttpServerConnection ae_conn;
    HttpResponse response;
    string[] content = [];

    this (HttpRequest request, HttpServerConnection conn) {
        ae_req = request;
        ae_conn = conn;
        response = new HttpResponse();
    }

    void setContentData() {
        string joined = "";
        foreach(str; content) {
            joined ~= str;
        }
        response.data = [Data(joined)];
    }

    int write(string data) {
        content ~= data;
        //response.appendData(data);
        return 1;
    }

    int addHeader(string header, string value) {
        response.headers[header] = value;
        return 1;
    }

    int setStatus(int status) {
        foreach (code, member; EnumMembers!HttpStatusCode) {
            if (code == status) {
                response.setStatus(member);
            }
        }
        return 1;
    }

    string[][] getHeaders() {
        string[][] headers;
        //headers.length = ae_req.headers.length;
        foreach (header, value; ae_req.headers) {
            headers ~= [header, value];
        }
        return headers;
    }

    string getHeader(string name) {
        return ae_req.headers[name];
    }

    string requestMethod() {
        return ae_req.method;
    }

    string uri() {
        return ae_req.resource();
    }

    string queryString() {
        return ae_req.queryString();
    }
}