module adapters.vibe;

import rack;

import std.traits;
import std.stdio;

import vibe.http.server;
import vibe.core.core : runEventLoop, lowerPrivileges;

class VibeHttp : RackAdapter {
    Rack handler;
    HTTPServerSettings http_settings;

    this() {
        http_settings = new HTTPServerSettings;
        http_settings.bindAddresses = ["::1", "127.0.0.1"];
    }

    this(Rack req_handler) {
        this();
        handler = req_handler;
    }

    void setHandler(Rack handler) {
        this.handler = handler;
    }

    void setPort(int port) {
        http_settings.port = cast(ushort)port;
    }

    void start () {
        listenHTTP(http_settings, &onRequest);
        lowerPrivileges();
        runEventLoop();
    }

    void stop () {
        //ae_server.close();
    }

    void onRequest(HTTPServerRequest request, HTTPServerResponse response) {
        auto req = new VibeRequest(request, response);
        handler.call(req);
        //req.setContentData();
        //conn.sendResponse(req.response);
    }
}

class VibeRequest : RackRequest {
    HTTPServerRequest  request;
    HTTPServerResponse response;

    this (HTTPServerRequest vibe_req, HTTPServerResponse vibe_resp) {
        request  = vibe_req;
        response = vibe_resp;
    }


    int write(string data) {
        response.bodyWriter.write(cast(ubyte[])data);
        return 1;
    }

    int addHeader(string header, string value) {
        response.headers[header] = value;
        return 1;
    }

    int setStatus(int status) {
        response.statusCode = status;
        return 1;
    }

    string[][] getHeaders() {
        string[][] headers;
        //headers.length = ae_req.headers.length;
        foreach (header, value; request.headers) {
            headers ~= [header, value];
        }
        return headers;
    }

    string getHeader(string name) {
        return request.headers[name];
        //return ae_req.headers[name];
    }

    string requestMethod() {
        switch (request.method) {
            case HTTPMethod.POST:   return "POST";
            case HTTPMethod.GET:    return "GET";
            case HTTPMethod.PATCH:  return "PATCH";
            case HTTPMethod.PUT:    return "PUT";
            case HTTPMethod.DELETE: return "DELETE";
            case HTTPMethod.HEAD:   return "HEAD";
            default: return "";
        }
    }

    string uri() {
        return request.path;
    }

    string queryString() {
        return request.queryString;
    }
}
