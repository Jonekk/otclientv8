#ifndef  HTTP_H
#define HTTP_H

#include <framework/global.h>
#include "result.h"

class Http {
public:
    Http() {}

    void init();
    void terminate();
    void poll();

    int get(const std::string& url, int timeout = 5);
    int post(const std::string& url, const std::string& data, int timeout = 5);
    int download(const std::string& url, std::string path, int timeout = 5);

    bool cancel(int id);
    int getProgress(int id);

    const std::map<std::string, HttpResult_ptr>& downloads() {
        return m_downloads;
    }
    void clearDownloads() {
        m_downloads.clear();
    }
    HttpResult_ptr getFile(std::string path) {
        if (!path.empty() && path[0] == '/')
            path = path.substr(1);
        auto it = m_downloads.find(path);
        if (it == m_downloads.end())
            return nullptr;
        return it->second;
    }

private:
    bool m_working = false;
    int m_operationId = 1;
    int m_speed = 0;
    size_t m_lastSpeedUpdate = 0;
    boost::asio::io_context m_ios;
    std::map<int, HttpResult_ptr> m_operations;
    std::map<std::string, HttpResult_ptr> m_downloads;
};

extern Http g_http;

#endif // ! HTTP_H
