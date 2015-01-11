module adapters.mongoose_binding;

import core.stdc.config;
import std.stdio;
import std.string;
import std.array;

version(Windows) {
    pragma(lib, "libmongoose");
} else {
    pragma(lib, "mongoose");
}

cstring toCstring(string c) {
    return cast(cstring) toStringz(c);
}

string fromCstring(cstring c, int len = -1) {
    string ret;
    if (c is null)
        return null;
    if (len == 0)
        return "";
    if (len == -1) {
        auto iterator = c;
        while(*iterator)
            iterator++;

        // note they are both byte pointers, so this is sane
        len = cast(int) iterator - cast(int) c;
        assert(len >= 0);
    }

    ret = cast(string) (c[0 .. len].idup);

    return ret;
}

template ExternC(T) if (is(typeof(*(T.init)) P == function)) {
    static if (is(typeof(*(T.init)) R == return)) {
        static if (is(typeof(*(T.init)) P == function)) {
            alias extern(C) R function(P) ExternC;
        }
    }
}

extern(System) {

    alias const(ubyte)* cstring;

    struct mg_header {
      cstring name;         // HTTP header name
      cstring value;        // HTTP header value
    };

    struct mg_connection {
      cstring request_method; // "GET", "POST", etc
      cstring uri;            // URL-decoded URI
      cstring http_version;   // E.g. "1.0", "1.1"
      cstring query_string;   // URL part after '?', not including '?', or NULL

      char remote_ip[48];         // Max IPv6 string length is 45 characters
      char local_ip[48];          // Local IP address
      ushort remote_port; // Client's port
      ushort local_port;  // Local port number

      int num_headers;            // Number of HTTP headers
      mg_header http_headers[30];

      char *content;              // POST (or websocket message) data, or NULL
      size_t content_len;         // Data length

      int is_websocket;           // Connection is a websocket connection
      int status_code;            // HTTP status code for HTTP error handler
      int wsbits;                 // First byte of the websocket frame
      void *server_param;         // Parameter passed to mg_add_uri_handler()
      void *connection_param;     // Placeholder for connection-specific data
      void *callback_param;       // Needed by mg_iterate_over_connections()
    }


/*
    struct mg_server {
      ns_server ns_server;
      union socket_address lsa;   // Listening socket address
      mg_handler_t event_handler;
      char *config_options[NUM_OPTIONS];
    };


    struct ns_server {
      void *server_data;
      sock_t listening_sock;
      struct ns_connection *active_connections;
      ns_callback_t callback;
      SSL_CTX *ssl_ctx;
      SSL_CTX *client_ssl_ctx;
      sock_t ctl[2];
    };

    struct ns_connection {
      ns_connection *prev, *next;
      ns_server *server;
      sock_t sock;
      socket_address sa;
      iobuf recv_iobuf;
      iobuf send_iobuf;
      SSL *ssl;
      void *connection_data;
      time_t last_io_time;
      unsigned int flags;
    };


    union socket_address {
      sockaddr sa;
      sockaddr_in sin;
      sockaddr_in6 sin6;
    };

*/



    struct mg_server; // Opaque structure describing server instance

    enum mg_result { MG_FALSE, MG_TRUE, MG_MORE };
    enum mg_event {
      MG_POLL = 100,  // Callback return value is ignored
      MG_CONNECT,     // If callback returns MG_FALSE, connect fails
      MG_AUTH,        // If callback returns MG_FALSE, authentication fails
      MG_REQUEST,     // If callback returns MG_FALSE, Mongoose continues with req
      MG_REPLY,       // If callback returns MG_FALSE, Mongoose closes connection
      MG_CLOSE,       // Connection is closed, callback return value is ignored
      MG_WS_HANDSHAKE,  // New websocket connection, handshake request
      MG_WS_CONNECT,  // New websocket connection established
      MG_HTTP_ERROR   // If callback returns MG_FALSE, Mongoose continues with err
    };

    alias mg_handler_t = ExternC!(int function (mg_connection *, mg_event));
    //typedef int (*mg_handler_t)(mg_connection *, mg_event);

    mg_server* mg_create_server(void *server_param, mg_handler_t handler);
    void mg_destroy_server(mg_server **);
    cstring mg_set_option(mg_server *, cstring opt, cstring val);
    int mg_poll_server(mg_server *, int milliseconds);
    cstring *mg_get_valid_option_names();
    cstring mg_get_option(const mg_server *server, cstring name);
    void mg_set_listening_socket(mg_server *, int sock);
    int mg_get_listening_socket(mg_server *);
    void mg_copy_listeners(mg_server *from, mg_server *to);
    void mg_iterate_over_connections(mg_server *, mg_handler_t, void *);
    mg_connection *mg_next(mg_server *, mg_connection *);
    void mg_wakeup_server(mg_server *);
    void mg_wakeup_server_ex(mg_server *, mg_handler_t, cstring , ...);
    mg_connection *mg_connect(mg_server *, cstring , int, int);

    // Connection management functions
    void mg_send_status(mg_connection *, int status_code);
    void mg_send_header(mg_connection *, cstring name, cstring val);
    size_t mg_send_data(mg_connection *, const void *data, int data_len);
    size_t mg_printf_data(mg_connection *, cstring format, ...);
    size_t mg_write(mg_connection *, const void *buf, int len);
    size_t mg_printf(mg_connection *conn, cstring fmt, ...);

    size_t mg_websocket_write(mg_connection *, int opcode, cstring data, size_t data_len);
    size_t mg_websocket_printf(mg_connection* conn, int opcode, cstring fmt, ...);

    void mg_send_file(mg_connection *, cstring path);

    cstring mg_get_header(const mg_connection *, cstring name);
    cstring mg_get_mime_type(cstring name, cstring default_mime_type);
    int mg_get_var(const mg_connection *conn, cstring var_name,
                   char *buf, size_t buf_len);
    int mg_parse_header(cstring hdr, cstring var_name, char *buf, size_t);
    int mg_parse_multipart(cstring buf, int buf_len,
                           char *var_name, int var_name_len,
                           char *file_name, int file_name_len,
                           cstring *data, int *data_len);

    
    // Utility functions
    // void *mg_start_thread(void *(*func)(void *), void *param);
    //alias mg_handler_t    = ExternC!(int function (mg_connection *, mg_event));
    alias mg_thread_handler = ExternC!(void * function (void *));
    void *mg_start_thread(mg_thread_handler, void *param);
    //void *ns_start_thread(mg_thread_handler, void *p);
    char *mg_md5(char buf[33], ...);
    int mg_authorize_digest(mg_connection *c, FILE *fp);
    int mg_url_encode(cstring src, size_t s_len, char *dst, size_t dst_len);
    int mg_url_decode(cstring src, int src_len, char *dst, int dst_len, int);
    int mg_terminate_ssl(mg_connection *c, cstring cert);

    // Templates support
    struct mg_expansion {
      cstring keyword;
      void function (mg_connection *) handler;
    };
    void mg_template(mg_connection *, cstring text,
                     mg_expansion *expansions);
}