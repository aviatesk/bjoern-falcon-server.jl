using Test, HTTP, JSON, Sockets
using bjoernfalconserver: @js


function test_server(host, port)

make_request(endpoint, body) = body === nothing ?
    HTTP.request("GET", "http://$host:$port/$endpoint") :
    HTTP.request("POST", "http://$host:$port/$endpoint", ["Content-Type" => "application/json"], body)

# test on response body
function test_response(f::Function, endpoint, body = nothing)
    r = make_request(endpoint, body)
    @test r.status == 200
    @test !isempty(r.body)
    body = String(r.body)
    f(body)
end

test_response("ping", nothing) do body
    @test body == "pong"
end

let data = @js { foo: "bar" }
    test_response("ping", data) do body
        @test body == @js { data }
    end
end

end # end test_server

function tryconnect(host, port)
    try
        return (Sockets.connect(host, port); true)
    catch err
        err isa Base.IOError && occursin(r"ECONNREFUSED", err.msg) && return false
        rethrow(err)
    end
end

@testset "server" begin
    host = get(ENV, "PYCALLSERVER_HOST", "0.0.0.0")
    port = parse(Int, get(ENV, "PYCALLSERVER_PORT", "8000"))
    while !tryconnect(host, port) end
    test_server(host, port)
end
