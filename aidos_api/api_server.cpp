#include <iostream>
#include <string>
#include <vector>
#include <netinet/tcp.h>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

int main() {
    Server svr;
    svr.set_tcp_nodelay(true);
    svr.set_keep_alive_max_count(100);
    svr.set_read_timeout(300, 0);
    svr.set_write_timeout(60, 0);

    Client ctrl_cli("localhost", 8082);
    ctrl_cli.set_tcp_nodelay(true);
    ctrl_cli.set_keep_alive(true);
    ctrl_cli.set_compress(true);
    ctrl_cli.set_read_timeout(300, 0);
    ctrl_cli.set_write_timeout(60, 0);
    ctrl_cli.set_connection_timeout(10);

    svr.Post("/generate", [&ctrl_cli](const Request& req, Response& res) {
        std::string prompt = req.body;
        std::cout << "Received prompt: " << prompt << std::endl;

        json body;
        body["prompt"] = prompt;

        auto ctrl_res = ctrl_cli.Post("/distribute", body.dump(), "application/json");

        if (ctrl_res) {
            res.set_content(ctrl_res->body, "application/json");
        } else {
            res.status = 500;
            res.set_content("{\"error\": \"Controller communication failed\"}", "application/json");
        }
    });

    // Cluster info proxy endpoints
    svr.Get("/nodes", [&ctrl_cli](const Request&, Response& res) {
        auto ctrl_res = ctrl_cli.Get("/nodes");
        if (ctrl_res) {
            res.set_content(ctrl_res->body, "application/json");
        } else {
            res.status = 502;
            res.set_content("{\"error\": \"Controller unreachable\"}", "text/plain");
        }
    });

    svr.Get("/cluster_memory", [&ctrl_cli](const Request&, Response& res) {
        auto ctrl_res = ctrl_cli.Get("/cluster_memory");
        if (ctrl_res) {
            res.set_content(ctrl_res->body, "application/json");
        } else {
            res.status = 502;
            res.set_content("{\"error\": \"Controller unreachable\"}", "text/plain");
        }
    });

    svr.Get("/rpc_endpoints", [&ctrl_cli](const Request&, Response& res) {
        auto ctrl_res = ctrl_cli.Get("/rpc_endpoints");
        if (ctrl_res) {
            res.set_content(ctrl_res->body, "application/json");
        } else {
            res.status = 502;
            res.set_content("{\"error\": \"Controller unreachable\"}", "text/plain");
        }
    });

    svr.Post("/launch", [&ctrl_cli](const Request& req, Response& res) {
        auto ctrl_res = ctrl_cli.Post("/launch", req.body, "application/json");
        if (ctrl_res) {
            res.set_content(ctrl_res->body, "application/json");
        } else {
            res.status = 502;
            res.set_content("{\"error\": \"Controller unreachable\"}", "text/plain");
        }
    });

    std::cout << "AIDOS API Server starting on port 8080..." << std::endl;
    svr.listen("0.0.0.0", 8080);

    return 0;
}
