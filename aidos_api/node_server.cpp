#include <iostream>
#include <string>
#include "../llama.cpp_src/vendor/cpp-httplib/httplib.h"
#include "../llama.cpp_src/vendor/nlohmann/json.hpp"

using json = nlohmann::json;
using namespace httplib;

int main(int argc, char** argv) {
    int port = (argc > 1) ? std::stoi(argv[1]) : 8081;
    Server svr;

    svr.Post("/compute", [](const Request& req, Response& res) {
        auto body = json::parse(req.body);
        std::string prompt = body["prompt"];
        std::cout << "Computing task: " << prompt << std::endl;

        // In a real system, this would call llama.cpp
        // For now, we mock the result
        json result;
        result["output"] = "Node result for: " + prompt;
        
        res.set_content(result.dump(), "application/json");
    });

    std::cout << "AIDOS Node Server starting on port " << port << "..." << std::endl;
    svr.listen("0.0.0.0", port);

    return 0;
}
