#include <iostream>
#include <string>
#include <vector>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

int main() {
    Server svr;

    svr.Post("/generate", [](const Request& req, Response& res) {
        std::string prompt = req.body;
        std::cout << "Received prompt: " << prompt << std::endl;

        json body;
        body["prompt"] = prompt;

        Client cli("localhost:8082");
        auto ctrl_res = cli.Post("/distribute", body.dump(), "application/json");
        
        if (ctrl_res) {
            res.set_content(ctrl_res->body, "application/json");
        } else {
            res.status = 500;
            res.set_content("{\"error\": \"Controller communication failed\"}", "application/json");
        }
    });

    std::cout << "AIDOS API Server starting on port 8080..." << std::endl;
    svr.listen("0.0.0.0", 8080);

    return 0;
}
