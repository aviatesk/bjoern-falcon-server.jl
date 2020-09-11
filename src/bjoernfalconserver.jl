module bjoernfalconserver


using JSON, PyCall

# API body
# --------

function ping_handler(data)
    @info "ping_handler: got " data
    return JSON.json(isempty(data) ? "pong" : (; data))
end

# entry point
# -----------

isdefined′(syms...) = all((isdefined(@__MODULE__, sym) for sym in syms))

# TODO
# - async initialization ?
# - distribute processes (listening on the same port) ?
function boot_server(host::AbstractString = get(ENV, "PYCALLSERVER_HOST", "0.0.0.0"),
                     port::Integer = parse(Int, get(ENV, "PYCALLSERVER_PORT", "8000"))
                     )
    @assert isdefined′(
        :ping_handler,
        # other handlers will come here ...
    ) "all the handlers (in Julia side) are not defined"

    @info "Server will listen to http://$host:$port"

    py"""
    import falcon
    import bjoern

    # helpers
    # ------

    def get_data(req):
        return req.stream.read(req.content_length or 0)

    # NOTE:
    # handleres are neeeded to be defined in toplevel, otherwise resource routers
    # can't recognize those embedded Julia functions correctly

    def ping_handler(data):
        return $ping_handler(data)

    # resources
    # ---------

    class PingResource(object):
        def on_get(self, req, resp):
            resp.body = ping_handler(get_data(req))

        def on_post(self, req, resp):
            resp.body = ping_handler(get_data(req))

    # main
    # ----

    app = falcon.API()
    app.add_route('/ping', PingResource())

    bjoern.run(wsgi_app = app, host = $host, port = $port)
    """
end

export  boot_server

end # module
