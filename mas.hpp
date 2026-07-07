#pragma once

#include <string>
#include <optional>
#include <sstream>
#include <vector>
#include <iomanip>
#include <cctype>

namespace mas {

struct params {
    std::string m;
    std::optional<std::string> k;
};

inline std::string url_decode(const std::string& s) {
    std::string out;
    for (size_t i = 0; i < s.size(); i++) {
        if (s[i] == '%' && i + 2 < s.size() &&
            std::isxdigit(static_cast<unsigned char>(s[i+1])) &&
            std::isxdigit(static_cast<unsigned char>(s[i+2]))) {
            auto hex = s.substr(i + 1, 2);
            out += static_cast<char>(std::stoi(hex, nullptr, 16));
            i += 2;
        } else {
            out += s[i];
        }
    }
    return out;
}

inline std::string url_encode(const std::string& s) {
    std::ostringstream out;
    for (unsigned char c : s) {
        if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
            out << c;
        } else {
            out << '%' << std::hex << std::uppercase << std::setw(2)
                << std::setfill('0') << static_cast<int>(c);
        }
    }
    return out.str();
}

inline params decode(const std::string& uri) {
    auto hash = uri.find('#');
    if (hash == std::string::npos) {
        throw std::invalid_argument("MAS: fragment is required");
    }
    auto frag = uri.substr(hash + 1);
    if (frag.empty()) {
        throw std::invalid_argument("MAS: fragment is required");
    }

    params p;
    std::istringstream stream(frag);
    std::string part;
    while (std::getline(stream, part, '&')) {
        auto eq = part.find('=');
        auto key = eq != std::string::npos ? part.substr(0, eq) : part;
        auto val = eq != std::string::npos ? part.substr(eq + 1) : "";
        key = url_decode(key);
        val = url_decode(val);

        if (key == "m") {
            if (val.empty()) {
                throw std::invalid_argument("MAS: m must not be empty");
            }
            p.m = val;
        } else if (key == "k" && !val.empty()) {
            p.k = val;
        }
    }

    if (p.m.empty()) {
        throw std::invalid_argument("MAS: m is required");
    }
    return p;
}

inline std::string encode(const params& p) {
    if (p.m.empty()) {
        throw std::invalid_argument("MAS: m is required and must be non-empty");
    }
    std::string s = "#m=" + url_encode(p.m);
    if (p.k.has_value() && !p.k->empty()) {
        s += "&k=" + url_encode(*p.k);
    }
    return s;
}

} // namespace mas
