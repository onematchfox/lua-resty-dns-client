use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: don't run semaphore in init phases
--- http_config eval
qq{
    init_worker_by_lua_block {
        local client = require("resty.dns.client")
        assert(client.init())
        local host = "httpbin.org"
        local typ = client.TYPE_A
        local answers, err = client.resolve(host, { qtype = typ })
        ngx.log(ngx.ERR, require("inspect")(answers))
        ngx.log(ngx.ERR, err)
    }
}
--- config
    location = /t {
        content_by_lua_block {
            ngx.say("OK")
        }
    }
--- request
GET /t
--- response_body
OK
--- error_log
127.0.0.1


=== TEST 2: don't have "dns lookup pool exceeded retries"
--- http_config eval
qq{
    init_worker_by_lua_block {
        local client = require("resty.dns.client")
        assert(client.init())
        local host = "httpbin.org"
        local typ = client.TYPE_A
        local answers, err = client.resolve(host, { qtype = typ })
        ngx.log(ngx.ERR, require("inspect")(answers))
        ngx.log(ngx.ERR, err)
    }
}
--- config
    location = /t {
        content_by_lua_block {
            ngx.say("OK")
        }
    }
--- request
GET /t
--- response_body
OK
--- error_log
127.0.0.1
