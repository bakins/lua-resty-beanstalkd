#; -*- mode: perl;-*-

# based on tableset.t from https://github.com/agentzh/lua-resty-memcached

use Test::Nginx::Socket;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_NGINX_BEANSTALKD_PORT} ||= 11300;

no_long_string();

run_tests();

__DATA__

=== TEST 1: put a simple string
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local beanstalkd = require "nginx.beanstalkd"
            local b = beanstalkd.new()
            local ok, err = b:put("foo")
            ngx.say(ok)
            b:close()
        ';
    }
--- request
GET /t
--- response_body
true
--- no_error_log
[error]
