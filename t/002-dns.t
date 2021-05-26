use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: lua-resty-dns init_worker
--- http_config eval
qq{
    $::HttpConfig
    init_worker_by_lua_block {
        local resolver = require "resty.dns.resolver"
        local r, err = resolver:new{
            nameservers = {"8.8.8.8", {"8.8.4.4", 53} },
            retrans = 5,  -- 5 retransmissions on receive timeout
            timeout = 2000,  -- 2 sec
            no_random = true, -- always start with first nameserver
        }

        if not r then
            ngx.log(ngx.ERR, "failed to instantiate the resolver: ", err)
            return
        end

        local answers, err, tries = r:query("www.google.com", nil, {})
        if not answers then
            ngx.log(ngx.ERR, "failed to query the DNS server: ", err)
            ngx.log(ngx.ERR, "retry history:", table.concat(tries, ",  "))
            return
        end

        if answers.errcode then
            ngx.log(ngx.ERR, "server returned error code: ", answers.errcode,
                    ": ", answers.errstr)
        end

        for i, ans in ipairs(answers) do
            ngx.log(ngx.ERR, ans.name, " ", ans.address or ans.cname,
                    " type:", ans.type, " class:", ans.class,
                    " ttl:", ans.ttl)
        end
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
API disabled in the context of init_worker_by_lua
