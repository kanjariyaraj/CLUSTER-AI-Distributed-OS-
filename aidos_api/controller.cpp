#include <iostream>
#include <string>
#include <vector>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

std::vector<std::string> nodes = {"localhost:8081"}; // Static list for now

int main() {
    Server svr;

    svr.Post("/distribute", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string prompt = body["prompt"];
        
        std::cout << "Distributing task: " << prompt << std::endl;

        // Simple Round Robin or just pick the first one for now
        std::string target_node = nodes[0];
        
        Client cli(target_node);
        auto node_res = cli.Post("/compute", body.dump(), "application/json");
        
        if (node_res) {
            res.set_content(node_res->body, "application/json");
        } else {
            res.status = 500;
            res.set_content("{\"error\": \"Node communication failed\"}", "application/json");
        }
    });

    std::cout << "AIDOS Controller starting on port 8082..." << std::endl;
    svr.listen("0.0.0.0", 8082);

    return 0;
}
